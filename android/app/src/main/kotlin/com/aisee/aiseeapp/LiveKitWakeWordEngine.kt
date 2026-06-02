package com.aisee.aiseeapp

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import ai.onnxruntime.TensorInfo
import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.nio.FloatBuffer
import java.util.ArrayDeque
import kotlin.math.ceil
import kotlin.math.max

class LiveKitWakeWordEngine(
    private val context: Context,
    private val channel: MethodChannel,
) {
    private data class Classifier(
        val modelName: String,
        val session: OrtSession,
        val inputName: String,
        val inputEmbeddings: Int,
    )

    private data class Detection(
        val modelName: String,
        val score: Float,
    )

    private val lock = Any()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val env: OrtEnvironment = OrtEnvironment.getEnvironment()
    private var sessionOptions: OrtSession.SessionOptions? = null
    private var melSession: OrtSession? = null
    private var melInputName: String = ""
    private var embeddingSession: OrtSession? = null
    private var embeddingInputName: String = ""
    private var classifiers: List<Classifier> = emptyList()
    private var threshold: Float = DEFAULT_THRESHOLD
    private var debounceMs: Long = DEFAULT_DEBOUNCE_MS
    private var chunkFrames: Int = defaultChunkFrames(MIN_EMBEDDINGS)
    private var lastDetectionAtMs: Long = 0
    @Volatile private var running = false
    private var audioRecord: AudioRecord? = null
    private var captureThread: Thread? = null

    fun configure(
        modelNames: List<String>,
        threshold: Float,
        debounceMs: Long,
    ) {
        val cleanedModels = modelNames.map { it.trim() }.filter { it.isNotEmpty() }
        require(cleanedModels.isNotEmpty()) { "LIVEKIT_WAKEWORD_MODELS is empty" }
        require(threshold > 0f && threshold <= 1f) {
            "LIVEKIT_WAKEWORD_THRESHOLD must be between 0 and 1"
        }
        require(debounceMs >= 0) { "LIVEKIT_WAKEWORD_DEBOUNCE_MS must be >= 0" }

        synchronized(lock) {
            closeSessions()
            val options = OrtSession.SessionOptions()
            sessionOptions = options
            melSession = env.createSession(readAsset("melspectrogram.onnx"), options)
            melInputName = firstInputName(requireNotNull(melSession))
            embeddingSession = env.createSession(readAsset("embedding_model.onnx"), options)
            embeddingInputName = firstInputName(requireNotNull(embeddingSession))
            classifiers = cleanedModels.map { modelName ->
                val session = env.createSession(readAsset(modelName), options)
                val inputName = firstInputName(session)
                Classifier(
                    modelName = modelName.substringBeforeLast(".onnx"),
                    session = session,
                    inputName = inputName,
                    inputEmbeddings = classifierInputEmbeddings(session, inputName),
                )
            }
            this.threshold = threshold
            this.debounceMs = debounceMs
            chunkFrames = defaultChunkFrames(
                classifiers.maxOfOrNull { it.inputEmbeddings } ?: MIN_EMBEDDINGS,
            )
        }
    }

    fun startListening() {
        synchronized(lock) {
            if (running) {
                return
            }
            require(melSession != null && embeddingSession != null && classifiers.isNotEmpty()) {
                "Wake word engine has not been configured"
            }
            if (context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                throw SecurityException("RECORD_AUDIO permission is required")
            }
            running = true
            captureThread = Thread(::captureLoop, "LiveKitWakeWord").also { it.start() }
        }
    }

    fun stopListening() {
        val threadToJoin: Thread?
        synchronized(lock) {
            running = false
            try {
                audioRecord?.stop()
            } catch (_: IllegalStateException) {
            }
            threadToJoin = captureThread
        }
        if (threadToJoin != null && threadToJoin !== Thread.currentThread()) {
            threadToJoin.join(STOP_JOIN_TIMEOUT_MS)
        }
        synchronized(lock) {
            releaseAudioRecord()
            if (captureThread === threadToJoin) {
                captureThread = null
            }
        }
    }

    fun dispose() {
        stopListening()
        synchronized(lock) {
            closeSessions()
        }
    }

    private fun captureLoop() {
        val frames = ArrayDeque<ShortArray>()
        val maxFrames = chunkFrames
        var detection: Detection? = null
        try {
            val record = createAudioRecord()
            synchronized(lock) {
                audioRecord = record
            }
            record.startRecording()
            val frame = ShortArray(FRAME_SAMPLES)
            while (running) {
                val read = record.read(frame, 0, frame.size, AudioRecord.READ_BLOCKING)
                if (!running) {
                    break
                }
                if (read <= 0) {
                    continue
                }
                frames.addLast(frame.copyOf(read))
                while (frames.size > maxFrames) {
                    frames.removeFirst()
                }
                if (frames.size < maxFrames) {
                    continue
                }
                val chunk = flattenFrames(frames)
                val nextDetection = predict(chunk)
                if (nextDetection != null && acceptDetection()) {
                    detection = nextDetection
                    running = false
                    break
                }
            }
        } catch (error: Exception) {
            Log.e(TAG, "Wake word capture failed", error)
            running = false
        } finally {
            synchronized(lock) {
                releaseAudioRecord()
                captureThread = null
            }
        }
        if (detection != null) {
            postDetection(detection)
        }
    }

    private fun createAudioRecord(): AudioRecord {
        val minBufferBytes = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        val bufferBytes = max(minBufferBytes, FRAME_SAMPLES * BYTES_PER_SAMPLE * 2)
        val record = AudioRecord(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferBytes,
        )
        if (record.state != AudioRecord.STATE_INITIALIZED) {
            record.release()
            throw IllegalStateException("AudioRecord failed to initialize for wake word")
        }
        return record
    }

    private fun releaseAudioRecord() {
        val record = audioRecord ?: return
        try {
            record.stop()
        } catch (_: IllegalStateException) {
        }
        record.release()
        audioRecord = null
    }

    private fun predict(audio: FloatArray): Detection? {
        val sessions = synchronized(lock) {
            Triple(
                requireNotNull(melSession),
                requireNotNull(embeddingSession),
                classifiers,
            )
        }
        val mel = runMel(sessions.first, audio)
        val embeddings = runEmbedding(sessions.second, mel)
        if (embeddings.isEmpty()) {
            return null
        }
        var best: Detection? = null
        for (classifier in sessions.third) {
            if (embeddings.size / EMBEDDING_SIZE < classifier.inputEmbeddings) {
                continue
            }
            val score = runClassifier(classifier, embeddings)
            if (score >= threshold && (best == null || score > best.score)) {
                best = Detection(modelName = classifier.modelName, score = score)
            }
        }
        return best
    }

    private fun runMel(session: OrtSession, audio: FloatArray): FloatArray {
        val inputShape = longArrayOf(1, audio.size.toLong())
        OnnxTensor.createTensor(env, FloatBuffer.wrap(audio), inputShape).use { tensor ->
            session.run(mapOf(melInputName to tensor)).use { result ->
                val output = result[0] as OnnxTensor
                val values = flattenFloats(output.value)
                val frames = outputFrames(output, values.size)
                val mel = FloatArray(frames * MEL_BINS)
                for (index in mel.indices) {
                    mel[index] = values[index] / 10.0f + 2.0f
                }
                return mel
            }
        }
    }

    private fun runEmbedding(session: OrtSession, mel: FloatArray): FloatArray {
        val frameCount = mel.size / MEL_BINS
        val windowCount = max(0, (frameCount - EMBEDDING_WINDOW) / EMBEDDING_STRIDE + 1)
        if (windowCount == 0) {
            return FloatArray(0)
        }
        val input = FloatArray(windowCount * EMBEDDING_WINDOW * MEL_BINS)
        var writeIndex = 0
        for (window in 0 until windowCount) {
            val startFrame = window * EMBEDDING_STRIDE
            for (frame in 0 until EMBEDDING_WINDOW) {
                val source = (startFrame + frame) * MEL_BINS
                for (bin in 0 until MEL_BINS) {
                    input[writeIndex++] = mel[source + bin]
                }
            }
        }
        val inputShape = longArrayOf(
            windowCount.toLong(),
            EMBEDDING_WINDOW.toLong(),
            MEL_BINS.toLong(),
            1,
        )
        OnnxTensor.createTensor(env, FloatBuffer.wrap(input), inputShape).use { tensor ->
            session.run(mapOf(embeddingInputName to tensor)).use { result ->
                return flattenFloats((result[0] as OnnxTensor).value).toFloatArray()
            }
        }
    }

    private fun runClassifier(classifier: Classifier, embeddings: FloatArray): Float {
        val availableEmbeddings = embeddings.size / EMBEDDING_SIZE
        val start = (availableEmbeddings - classifier.inputEmbeddings) * EMBEDDING_SIZE
        val input = FloatArray(classifier.inputEmbeddings * EMBEDDING_SIZE)
        System.arraycopy(embeddings, start, input, 0, input.size)
        val inputShape = longArrayOf(
            1,
            classifier.inputEmbeddings.toLong(),
            EMBEDDING_SIZE.toLong(),
        )
        OnnxTensor.createTensor(env, FloatBuffer.wrap(input), inputShape).use { tensor ->
            classifier.session.run(mapOf(classifier.inputName to tensor)).use { result ->
                return firstFloat((result[0] as OnnxTensor).value)
            }
        }
    }

    private fun acceptDetection(): Boolean {
        val now = System.currentTimeMillis()
        if (now - lastDetectionAtMs < debounceMs) {
            return false
        }
        lastDetectionAtMs = now
        return true
    }

    private fun postDetection(detection: Detection) {
        mainHandler.post {
            channel.invokeMethod(
                "onWakeWordDetected",
                mapOf(
                    "phrase" to detection.modelName,
                    "score" to detection.score.toDouble(),
                ),
            )
        }
    }

    private fun closeSessions() {
        classifiers.forEach { it.session.close() }
        classifiers = emptyList()
        melSession?.close()
        melSession = null
        embeddingSession?.close()
        embeddingSession = null
        sessionOptions?.close()
        sessionOptions = null
    }

    private fun readAsset(name: String): ByteArray {
        return context.assets.open(name).use { it.readBytes() }
    }

    private fun firstInputName(session: OrtSession): String {
        return session.inputNames.iterator().next()
    }

    private fun classifierInputEmbeddings(session: OrtSession, inputName: String): Int {
        val inputInfo = session.inputInfo[inputName]?.info as? TensorInfo
        val shape = inputInfo?.shape
        val length = shape?.getOrNull(1)?.toInt() ?: MIN_EMBEDDINGS
        return if (length > 0) length else MIN_EMBEDDINGS
    }

    private fun outputFrames(output: OnnxTensor, valueCount: Int): Int {
        val shape = (output.info as? TensorInfo)?.shape
        val fromShape = shape?.getOrNull(2)?.toInt()
        if (fromShape != null && fromShape > 0) {
            return fromShape
        }
        return valueCount / MEL_BINS
    }

    private fun flattenFrames(frames: ArrayDeque<ShortArray>): FloatArray {
        val sampleCount = frames.sumOf { it.size }
        val audio = FloatArray(sampleCount)
        var writeIndex = 0
        for (frame in frames) {
            for (sample in frame) {
                audio[writeIndex++] = sample / SHORT_SCALE
            }
        }
        return audio
    }

    private fun flattenFloats(value: Any?): List<Float> {
        val output = mutableListOf<Float>()
        collectFloats(value, output)
        return output
    }

    private fun firstFloat(value: Any?): Float {
        return flattenFloats(value).firstOrNull() ?: 0f
    }

    private fun collectFloats(value: Any?, output: MutableList<Float>) {
        when (value) {
            null -> return
            is Float -> output.add(value)
            is Double -> output.add(value.toFloat())
            is Number -> output.add(value.toFloat())
            is FloatArray -> value.forEach { output.add(it) }
            is DoubleArray -> value.forEach { output.add(it.toFloat()) }
            is Array<*> -> value.forEach { collectFloats(it, output) }
            else -> throw IllegalStateException("Unexpected ONNX output: ${value.javaClass.name}")
        }
    }

    companion object {
        private const val TAG = "LiveKitWakeWord"
        private const val SAMPLE_RATE = 16_000
        private const val FRAME_SAMPLES = 1_280
        private const val BYTES_PER_SAMPLE = 2
        private const val MEL_BINS = 32
        private const val EMBEDDING_WINDOW = 76
        private const val EMBEDDING_STRIDE = 8
        private const val EMBEDDING_SIZE = 96
        private const val MIN_EMBEDDINGS = 16
        private const val DEFAULT_THRESHOLD = 0.5f
        private const val DEFAULT_DEBOUNCE_MS = 2_000L
        private const val STOP_JOIN_TIMEOUT_MS = 1_500L
        private const val SHORT_SCALE = 32768.0f

        private fun defaultChunkFrames(inputEmbeddings: Int): Int {
            val melFrames = EMBEDDING_WINDOW + EMBEDDING_STRIDE * (inputEmbeddings - 1)
            val samples = (melFrames + 3) * 160
            return ceil(samples.toDouble() / FRAME_SAMPLES).toInt()
        }
    }
}
