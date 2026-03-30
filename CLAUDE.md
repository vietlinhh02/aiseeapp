# Tham chiếu phong cách UI (Figma Prodify) — cho AI / Claude

## Quan trọng: không phải spec cho app này

File Figma **Prodify** là thiết kế cho **một app khác**. Repo **aiseeapp** (và các sản phẩm bạn chỉ định) **chỉ mượn phong cách** (style reference), **không** bắt buộc:

- copy nguyên luồng màn hình / IA của Prodify,
- dùng tên **Prodify**, copy mockup, hay asset nhận diện của file đó,
- làm pixel-perfect từng frame nếu không khớp nghiệp vụ app thật.

**Việc cần làm khi code:** áp **ngôn ngữ thị giác** — màu, font, độ bo, quy tắc CTA, chip, dark layout — lên **màn hình và luồng đúng của app đang làm**.

Phần còn lại của tài liệu mô tả **chi tiết file Prodify** để agent hiểu *phong cách đó gồm gì*; coi như **từ vựng thiết kế**, không phải checklist màn hình bắt buộc cho aiseeapp.

### Mục đích tài liệu

- Ghi lại **token + pattern** trích từ Figma MCP để không phải mở Figma mỗi lần.
- Khi implement: **ưu tiên** nghiệp vụ + design riêng của app; chỉ căn chỉnh **look & feel** theo các mục 2–6 (nguyên tắc, màu, type, component style).

---

## 1. Nguồn & cách tra cứu

| Thuộc tính | Giá trị |
|------------|---------|
| File Figma | [Prodify](https://www.figma.com/design/Z2puEDKMPEUvfZPRFw4NK7/Prodify) |
| `fileKey` | `Z2puEDKMPEUvfZPRFw4NK7` |
| Quy ước `node-id` trong URL | `749-7174` → node Figma `749:7174` (thay `-` bằng `:`) |

### Bảng màn hình (deep link)

| # | Tên frame (trong export) | Node | URL Dev Mode |
|---|---------------------------|------|--------------|
| 1 | Onboard 1 / Splash | `749:7174` | [Mở](https://www.figma.com/design/Z2puEDKMPEUvfZPRFw4NK7/Prodify?node-id=749-7174&m=dev) |
| 2 | Login | `749:7188` | [Mở](https://www.figma.com/design/Z2puEDKMPEUvfZPRFw4NK7/Prodify?node-id=749-7188&m=dev) |
| 3 | To-do dropdown / Home Overview | `749:7256` | [Mở](https://www.figma.com/design/Z2puEDKMPEUvfZPRFw4NK7/Prodify?node-id=749-7256&m=dev) |
| 4 | Week View / Calendar | `749:7528` | [Mở](https://www.figma.com/design/Z2puEDKMPEUvfZPRFw4NK7/Prodify?node-id=749-7528&m=dev) |
| 5 | Profile (drawer menu) | `749:7508` | [Mở](https://www.figma.com/design/Z2puEDKMPEUvfZPRFw4NK7/Prodify?node-id=749-7508&m=dev) |
| 6 | Profile / Focus complete | `749:8001` | [Mở](https://www.figma.com/design/Z2puEDKMPEUvfZPRFw4NK7/Prodify?node-id=749-8001&m=dev) |

**Khung thiết kế:** nhiều màn dùng **430px** ngang (iPhone 15 Pro Max mockup) + status bar giả **60px** cao + home indicator **34px**. Khi code Flutter: dùng **layout responsive**, coi 430px là **reference width**, không hard-code pixel tuyệt đối trừ khi cần khớp pixel-perfect.

---

## 2. Nguyên tắc UI/UX tổng thể

### 2.1 Giọng điệu trải nghiệm

- **Dark mode first:** nền `#060913` (gần đen pha xanh navy), giảm chói, cảm giác “tập trung / productivity”.
- **Tương phản cao:** chữ chính trắng trên nền tối; CTA chính thường là **nút trắng + chữ đậm tối** để nổi bật một hành động.
- **Tối giản có chủ đích:** ít họa tiết; nhấn **typography**, **khoảng trắng**, **card** và **chip** để phân lớp.
- **Micro-copy thân thiện:** ví dụ màn focus *“Yayy ! you’ve been focus…”* — giọng informal; có thể chuẩn hóa ngữ pháp khi production.

### 2.2 Hình học & độ bo

- **Pill / stadium:** nút social, input đăng nhập: bo tròn cực lớn (tương đương `border-radius: 100px` trong export).
- **Card / khối nội dung:** bo **12px** (`--lg` trong file) hoặc **8px** (ô notification, một số schedule card).
- **Nút primary full-width (Login, Logout, Set Another focus):** bo **~31px** (không phải full pill nhưng vẫn mềm).
- **Bottom bar (Prodify):** container bo **~16px**; tab active là pill nền chartreuse. **aiseeapp — nav User UI (low vision):** pill tab active **trắng** (`#FFFFFF`), thanh nổi bo **~32px** — xem mục **4.3**.

### 2.3 Hệ thống spacing (từ biến Figma)

Trong export xuất hiện token:

| Token | Giá trị | Gợi ý Flutter |
|-------|---------|----------------|
| `--spacing/1x` | 4px | `4` |
| `--spacing/2x` | 8px | `8` |
| `--spacing/4x` | 16px | `16` |
| `--full` (radius chip) | pill | `StadiumBorder` hoặc `BorderRadius.circular(999)` |

Khoảng cách lặp lại giữa các cụm dọc: **8 / 16 / 32** (ví dụ section Overview ↔ Project: **32px**).

### 2.4 Điều hướng trong file Prodify (chỉ tham khảo)

Đây là **IA của app Prodify** trong Figma — **không** áp cứng vào app khác. Chỉ hữu ích nếu bạn cần hiểu *cách họ xếp layout* (header profile → nội dung → bottom bar).

- Splash → Login → Home (Overview, project, task) → Calendar → Drawer → màn focus hoàn thành.

App thật của bạn có thể **bỏ hết** các màn này và chỉ giữ **dark + card + chip + nút trắng** theo token.

---

## 3. Typography (chuẩn hóa từ Figma)

**Font chính:** **Plus Jakarta Sans** (Regular 400, SemiBold 600, Bold 700).

| Style name (trong Figma) | Size | Weight | Line height | Letter-spacing | Màu điển hình |
|--------------------------|------|--------|-------------|----------------|---------------|
| Header SM Bold | 24 | Bold (700) | 1 (tight) | -0.2px | `#FFFFFF` |
| Header SM SemiBold | 24 | SemiBold (600) | 1 / 1.2 | -0.2 / -0.5px | `#FFFFFF` |
| Body Text 1 SemiBold | 20 | SemiBold | 26px | -0.2px | `#FFFFFF` |
| Body Text 2 Bold | 16 | Bold | 24px | -0.2px | `#060913` trên nền trắng; hoặc `#FFFFFF` trên nền tối |
| Body Text 3 SemiBold | 14 | SemiBold | 20px | -0.2px | `#FFFFFF` |
| Body Text 4 Regular | 12 | Regular | 18px | -0.2px | `#B0B0B0`, `#888888`, `#5D5D5D` tùy vai trò |
| Body Text 4 Bold | 12 | Bold | 18px | -0.2px | link / nhãn phụ đậm |
| Chip / badge | 12 | SemiBold | ~1.2 | -0.5px | tùy variant |

**SF Pro** chỉ dùng trong **status bar** mockup (9:41, v.v.) — **không** cần nhúng vào app; Flutter dùng system status bar.

---

## 4. Màu (design tokens)

### 4.1 Bảng đầy đủ (hex từ biến file)

| Token | Hex | Dùng cho |
|-------|-----|----------|
| Black/950 | `#060913` | `scaffold` / nền app |
| White/50 | `#FFFFFF` | Text primary, nút nền sáng, icon trên nền tối |
| Black/300 | `#B0B0B0` | Subtitle, secondary text, date lines |
| Black/400 | `#888888` | Border input login, legal secondary, label nhỏ |
| Black/600 | `#5D5D5D` | Placeholder, icon nền tròn (đóng drawer) |
| Black/700 | `#4F4F4F` | Text chi tiết tối |
| Black/900 | `#3D3D3D` | Border card calendar (`schedule-card`), divider drawer |
| White/950 | `#292929` | Surface card đậm, nút notification |
| White/100 | `#EFEFEF` | (xuất hiện trong spec) |
| Black/50 | `#F6F6F6` | (xuất hiện trong spec) |
| Black/100 | `#E7E7E7` | (xuất hiện trong spec) |
| Chartreuse/50 | `#F4FFE6` | **Ngày được chọn** trên calendar strip |
| Chartreuse/100 | `#E6FEC9` | Nền chip “Not Urgent” / soft |
| Chartreuse/300 | `#ACF75F` | Chartreuse sáng (progress, nhấn mạnh) |
| Chartreuse/500 | `#6DD210` | Accent chính (logo dot, progress active) |
| Chartreuse/600 | `#52A808` | Link “Sign up”, text nhấn mạnh xanh |
| Chartreuse/700 | `#3F800B` | Chartreuse đậm |
| Chartreuse/900 | `#2E5512` | Text trên nền chip xanh nhạt |
| Pomegranate/100 | `#FFE5E0` | Nền chip **Urgent** |
| Pomegranate/700 | `#C52B10` | Chữ chip **Urgent** |
| Bright Sun/700 / 100 | (trong file) | Category / trạng thái phụ — mở Figma nếu cần đồng bộ 100% |

### 4.2 Quy tắc gán màu semantic (cho code)

- **backgroundApp** → `Black/950`
- **surfaceCard** → `#3D3D3D` hoặc `White/950` tùy màn (Overview dùng `#3D3D3D` cho stat card; calendar card viền `#3D3D3D`)
- **textPrimary** → `White/50`
- **textSecondary** → `Black/300`
- **textTertiary** → `Black/400`
- **borderDefault** → `#5D5D5D` (project card) hoặc `#3D3D3D` (schedule)
- **accent** → Chartreuse scale; **dangerSoft** → Pomegranate 100 + 700

### 4.3 Token nav User UI (AiSee — `StyleTokens`)

Thanh điều hướng người dùng chính (thị lực thấp / a11y): pill đang chọn **nền trắng** + chữ/icon tối; thanh nổi bo góc **~32px** (gấp đôi mức 16px tham chiếu).

| Token (Flutter) | Hex | Dùng cho |
|-----------------|-----|----------|
| `navSelectedPill` | `#FFFFFF` | Nền pill tab đang chọn; icon công cụ trùng token nếu cần nhấn mạnh |
| `navSelectedOnPill` | `#060913` | Chữ và icon trên pill |
| `navUnselectedIcon` | `#888888` | Icon tab không chọn |
| `navGlassTint` | `#292929` ~92% alpha (`0xEA292929`) | Nền thanh nổi — đủ đậm để luôn thấy (tránh chỉ ~10% trắng trên nền tối) |
| `navGlassBorder` | `#5D5D5D` | Viền thanh nổi |

Bảng **Chartreuse** ở mục 4.1 vẫn mô tả **file Figma Prodify**; khi code nav User trong aiseeapp, ưu tiên bảng này.

---

## 5. Mô tả chi tiết từng màn *(trong file Prodify — tham khảo layout / style)*

Các mục dưới mô tả **đúng file gốc**. Khi làm app khác: lấy **quy tắc** (màu, bo góc, typography, nút) áp vào **màn của bạn**, không nhất thiết có Splash/Calendar/Task giống hệt.

### 5.1 Splash — `749:7174` (Onboard 1)

- **Nền:** `#060913` full screen.
- **Nội dung:** logo **Prodify** (wordmark), chữ trắng; **chấm trên chữ i** màu chartreuse (`#6DD210` trong tài liệu token).
- **Vị trí:** logo căn giữa theo mockup (export đặt layer logo khoảng giữa dọc).
- **UX:** không nút; chuyển màn sau timer hoặc tap (định nghĩa product).
- **Implementation:** export SVG/PNG logo từ Figma Assets; không dùng URL MCP làm production.

### 5.2 Login — `749:7188`

**Cấu trúc dọc (từ trên xuống):**

1. **Status bar** (mockup — bỏ qua khi implement thật).
2. **Khối nội dung** `left: 16px`, `width: ~398px`, bắt đầu khoảng `top: 398px` trong frame cố định — trên thiết bị thật dùng `SafeArea` + scroll nếu bàn phím mở.
3. **Tiêu đề + mô tả** (căn giữa, `width` ~288px cho text block):
   - **“Login”** — 24 Bold, trắng, `tracking -0.2px`.
   - Subtitle — 12 Regular, `#B0B0B0`, line height 18px: *“Log in to your account to save your progress and to sync it on another devices.”* (ngữ pháp mockup chưa chuẩn — nên sửa: *another device* / *other devices*).
4. **Khoảng** 16px (`gap`) trước cụm tiếp.
5. **Hàng social** — hai nút **flex 1** cạnh nhau, `gap` 8px:
   - Nền trắng, `padding` ngang lớn (~60px), dọc ~18px, bo pill.
   - Icon **20×20**, text **“Using Google”** / **“Using iCloud”** — 16 Bold, `#060913`.
6. **Separator “or”** — 14 SemiBold, trắng, căn giữa.
7. **Form:**
   - **Username:** viền `#888888`, cao **60px**, `px 24` `py 16`, placeholder 12 Regular `#5D5D5D` “Username”.
   - **Password:** cùng style; nội dung mask; icon **show/hide** 20×20 bên phải.
   - `gap` 8px giữa hai field.
8. **Hàng Forgot / Sign up** — `padding` ngang 16px, `space-between`:
   - Trái: **“Forgot Password”** — 12 Bold trắng.
   - Phải: *“Didn’t have an account ?”* 12 Regular `#888` + **“Sign up”** 12 Bold `#52A808`.
9. **Nút “Login”** — full width, nền trắng, chữ `#060913` 16 Bold, `py 18` `px 60`, `rounded ~31px`.
10. **Legal:** đoạn nhỏ 12px; phần lớn `#888`, **Terms of Services** & **Privacy Policy** bold trắng. Copy mockup: *“By continuing you agree prodify …”* (có thể sửa brand + “Terms of Service”).

**Home indicator** 34px (mockup).

### 5.3 Home / Overview — `749:7256` (To-do dropdown)

**Header (dưới status bar):**

- `top ~76px`: hàng profile + nút phải.
- **Avatar:** 48×48, tròn.
- **Tên:** 14 SemiBold trắng, line 20px — ví dụ “Gilang Permana”.
- **Subtitle:** 12 Regular `#5D5D5D` — “You in your zone”.
- **Nút phải:** nền `#292929`, bo **8px**, padding **14px**, icon **20×20** (chuông / notification trong export).

**Vùng scroll chính** (`left 16px`, `top ~143px`, `width ~399px`):

- **Section “Overview”** — tiêu đề 24 SemiBold trắng; `gap` 16px tới hàng stat.
- **Hai thẻ stat** cạnh nhau (`gap` 4px trong một chỗ export, nhưng cụm lớn dùng 16px giữa title và cards):
  - Nền `#3D3D3D`, bo **12px**, `padding` **16px**.
  - Label 12 Regular `#888` (“Task Complited” / “Project Complited” — typo trong mockup).
  - Số 24 SemiBold trắng (“321/420”, “42/45”).
- **Section “Project”** — tiêu đề 24 SemiBold; bên phải nút pill trắng **“On Going”** 12 Bold `#060913`, `px 12` `py 10`, icon 20.
- **Carousel project card** — width card ~**295px**, bo **12px**, viền `#5D5D5D`:
  - Header: title 16 Bold trắng (“House  Chore”) + fraction 12 Regular `#888` (“20/40”).
  - **Progress:** thanh mảnh (layer vector trong Figma) — màu chartreuse trên nền tối.
  - **Task rows:** `padding` 16px, `gap` 16px giữa cột text và checkbox; border bottom `#5D5D5D`.
  - Mỗi task: title 12 SemiBold trắng; date 12 Regular `#B0B0B0`; chip bên phải; checkbox **24×24** outline.

**Chip trên Home (ví dụ):**

- **Not Urgent:** nền `#E6FEC9`, chữ `#2E5512`, 12 SemiBold, pill, `px 8` `py 4`.
- **Urgent:** (ở màn khác) nền `#FFE5E0`, chữ `#C52B10`.

**On Going task** (phần dưới): tiêu đề section + list tương tự; chip **School Task** có thể dùng màu category (coral / pomegranate — xem frame đầy đủ trong Figma).

**Bottom navigation:** thanh nổi tối, bo 16px; tab **To-Do** active = pill chartreuse + icon + label; các tab khác outline xám; nút **+** tròn nền trắng.

### 5.4 Calendar — `749:7528` (Week View)

**Header:** giống Home (avatar + tên + subtitle) — bên phải có thể là title **“Calendar”** (24 SemiBold) thay vì chuông (xem đúng frame trong file).

**Thanh tháng / filter:**

- “January” + dropdown **“Week”** (nút trắng pill / outline tùy variant).

**Strip ngày:** các ô **50px** wide (trong export), bo **16px**, `padding` 8px, `gap` 16px giữa các ô theo trục dọc nội bộ ô:
- **Inactive:** viền `#3D3D3D`, nền trong suốt/tối, label ngày + số.
- **Selected:** nền **`#F4FFE6`** (Chartreuse/50), dot dưới cùng màu chartreuse đậm.

**Nhóm “Today” / “Tomorrow”:**

- Header hàng: trái 24 SemiBold “Today”; phải 12 Regular `#B0B0B0` “2 Events”.
- **Schedule card:** `width ~398px`, viền `#3D3D3D`, bo **8px**, `px 8` `py 16`:
  - Cột trái: dot / icon 24px.
  - Title 16 SemiBold trắng; hàng giờ: icon 16px + “04.00 - 06.00” 12 Regular `#B0B0B0`.
  - Chip **Urgent** (pomegranate) góc phải hàng title.
  - Mô tả 12 Regular `#B0B0B0`, tối đa ~2 dòng.

**Bottom bar:** tab **Calendar** active (pill chartreuse + label).

### 5.5 Menu / Drawer — `749:7508` (Profile)

- **Sidebar** `width ~414px`, nền `#060913`, `padding` top 48, bottom 16, ngang 16; bo góc phải **12px**; `shadow` nhẹ (export: `0 4px 4px rgba(80,80,80,0.25)`).
- **Header drawer:** logo Prodify (~81×24) + nút đóng tròn **24×24** nền `#5D5D5D`, icon X.
- **Menu items** (full width ~382px): mỗi dòng `py 24` `px 16`, `gap` 19px giữa icon 24px và text; **border** trên/dưới `#3D3D3D`:
  - “Edit Your Profile”
  - “Settings”
  - “Feedback & Support”
- **Logout:** full width, nền trắng, chữ `#060913` 16 Bold, `py 18` `px 60`, bo ~31px — đặt **đáy** cụm (trong export dùng flex `justify-between`).

**Status bar** mockup dark (trắng trên đen) — bản `749:7508` dùng variant **dark true** cho time.

### 5.6 Focus hoàn thành — `749:8001`

- Nền `#060913`.
- **Khối nội dung** căn giữa: `gap` **64px** giữa illustration và text.
- **Illustration:** ~323×360 (tỷ lệ trong export) — minh họa line-art trắng (thumbs up).
- **Headline:** 20 SemiBold trắng, line 26px: *“Yayy ! you’ve been focus for 45 Minutes”*.
- **Body:** 12 Regular `#B0B0B0`, line 18px, `width` ~223px (có thể full width responsive); mockup dùng Lorem.
- **CTA:** “Set Another focus” — cùng style nút primary trắng full width như Login.

---

## 6. Pattern component (theo style reference — đặt tên tuỳ app)

Tên dưới đây chỉ là **gợi ý**; trong code có thể đổi thành `AiseePrimaryButton`, v.v.

### 6.1 Primary button (nền trắng / chữ tối)

- Nền `#FFFFFF`, text `#060913`, font 16 Bold, line 24px.
- Padding: ~`horizontal 60`, `vertical 18` (scale theo màn hình).
- `BorderRadius` ~31.

### 6.2 Social / OAuth button (pill trắng)

- Giống nền trắng; icon 20; text 16 Bold `#060913`; pill radius; flex equal width trong hàng.

### 6.3 Text field (viền xám, pill)

- Height 60; horizontal padding 24; vertical 16; border `#888888` 1px; radius pill; hint 12 Regular `#5D5D5D`.

### 6.4 Stat card (nền `#3D3D3D`)

- Background `#3D3D3D`; radius 12; padding 16; label 12 `#888`; value 24 white SemiBold.

### 6.5 Card có viền + progress (kiểu project)

- Border `#5D5D5D`; radius 12; inner sections với divider; progress bar chartreuse.

### 6.6 Hàng task (title + meta + chip + checkbox)

- Padding 16; border bottom; title 12 SemiBold; meta 12 Regular `#B0B0B0`; trailing chip + 24 checkbox.

### 6.7 Chip (Urgent / soft)

- **Urgent:** bg `#FFE5E0`, text `#C52B10`, 12 SemiBold, pill, px 8 py 4.
- **Not urgent / soft:** bg `#E6FEC9`, text `#2E5512`, same padding.

### 6.8 Bottom bar nổi (pill — không glassmorphism)

- Floating; **nền đen** (`#000000`); bo pill (`999`); viền trắng 60%; padding 16px.
- Active tab: **pill trắng** (`#FFFFFF`) + icon 24 dark + label 14 SemiBold dark; gap 8; height 48; px 12.
- Inactive tab: pill `#3D3D3D` + icon 24 gray (`#888888`); **không** có label; height 48.
- Nút **+**: pill trắng 48×48, icon plus 12 dark.
- Layout: `Row` spaceBetween.
- **Không dùng glassmorphism** (không blur, không gradient tint, không BackdropFilter).

---

## 7. Hành vi & trạng thái (Figma không đầy đủ — agent cần bổ sung)

- **Loading / skeleton:** không có trong các node đã export — thêm pattern nhất quán (shimmer tối hoặc `CircularProgressIndicator` chartreuse).
- **Empty state:** không có — định nghĩa illustration + copy ngắn.
- **Lỗi form:** highlight viền input (ví dụ Pomegranate) + message 12px dưới field.
- **Touch target:** tối thiểu **48dp** theo guideline; mockup có chỗ 24px — mở rộng vùng chạm.

---

## 8. Accessibility

- Tương phản chữ trắng trên `#060913` thường đạt WCAG cho text lớn; text 12px `#888` trên nền tối cần kiểm tra — có thể sáng hơn một bậc cho body quan trọng.
- Nút chỉ màu: bổ sung **Semantics** / `tooltip` / `aria-label` tương đương Flutter.
- **Focus order:** drawer mở → trap focus; đóng bằng nút X và swipe (nếu có).

---

## 9. Flutter — hướng dẫn triển khai (gợi ý code)

Áp dụng khi bạn muốn **theme gần phong cách** này cho app đang code (ví dụ aiseeapp), không nhất thiết đặt tên class là Prodify.

1. **`ThemeExtension`** hoặc class tập trung màu (ví dụ `StyleTokens`) chứa hex ở mục 4 — chỉ lấy subset cần dùng; **nav User UI** dùng mục **4.3** (pill trắng), không lấy chartreuse cho tab active.
2. **`ThemeData`:** có thể dùng `scaffoldBackgroundColor: Color(0xFF060913)`, `brightness: Brightness.dark` nếu muốn dark giống reference.
3. **Font:** `google_fonts` + Plus Jakarta Sans **nếu** muốn khớp typeface reference; có thể đổi font khác vẫn giữ **cấp bậc** size/weight tương đương.
4. **Không** render status bar / Dynamic Island giả; dùng `SafeArea`.
5. **Asset:** logo / illustration lấy từ **thiết kế của app bạn**; không bắt buộc export từ file Prodify.
6. **Icon:** dùng SVG từ `assets/icons/nav/` (xem mục 12) + `SvgPicture.asset()` với `ColorFilter.mode(color, BlendMode.srcIn)` để tint màu. **Không dùng Material Icons** (`Icons.*`).

---

## 10. Checklist khi “chỉ copy phong cách”

- [ ] Token màu / spacing / radius thống nhất trong code (lấy từ mục 4 & 2 tùy nhu cầu); nav User AiSee: mục **4.3**
- [ ] Typography có hierarchy rõ (tương đương bảng mục 3, có thể đổi font)
- [ ] CTA chính: nền sáng + chữ tối trên app dark (nếu theo style này)
- [ ] Chip / badge: dùng cặp màu chartreuse / pomegranate **chỉ khi** UX app bạn cần loại trạng thái tương tự
- [ ] **Không** nhét đủ màn Prodify nếu không thuộc scope app
- [ ] Copy & brand theo **app thật**, không dùng “Prodify” / lorem của mockup
- [ ] Asset từ nguồn đúng dự án; không phụ thuộc URL MCP Figma

---

## 11. Phụ lục — copy gốc mockup (để đối chiếu)

| Vị trí | Text gốc |
|--------|----------|
| Login subtitle | Log in to your account to save your progress and to sync it on another devices. |
| Social | Using Google / Using iCloud |
| Legal | By continuing you agree prodify Terms of Services & Privacy Policy |
| Overview | Task Complited / Project Complited |
| Project | House Chore / Monthly Grocery / Thu, 14 Juny 2024 |
| Focus | Yayy ! you’ve been focus for 45 Minutes / Set Another focus |
| Drawer | Edit Your Profile / Settings / Feedback & Support / Logout |

---

## 12. Icon catalog — SVG từ Figma Icon Family (`381:3605`)

Tất cả icon nằm trong `assets/icons/nav/`. Đã export từ Figma Prodify **Icon Family** (node `381:3605`), format SVG, stroke `#060913`, dùng `ColorFilter.mode(color, BlendMode.srcIn)` để tint bất kỳ màu nào trong Flutter.

### 12.1 Icon đang dùng trong app

| File | Figma name | Dùng ở đâu |
|------|-----------|------------|
| `ic_wave.svg` | wave | Nav tab: Trợ lý (waveform giọng nói) |
| `ic_category.svg` | Category | Nav tab: Công cụ (lưới 4 ô) |
| `ic_profile.svg` | Profile | Nav tab: Cá nhân (người) |
| `ic_plus.svg` | Plus2 | Nav: nút + thêm mới |
| `ic_camera.svg` | Camera | Tools: Camera — AI nhìn hộ |
| `ic_3user.svg` | 3 User | Tools: Danh bạ người thân |
| `ic_arrow_right.svg` | Arrow - Right 2 | Tools: chevron indicator |
| `ic_voice.svg` | Voice | Personal: Tin nhắn thoại |
| `ic_activity.svg` | Activity | Personal: Nhật ký sức khỏe |
| `ic_heart.svg` | Heart | Personal: Lịch uống thuốc |
| `ic_calendar.svg` | Calendar | Personal: Lịch hẹn |
| `ic_delete.svg` | Delete | Personal: Xoá nhắc nhở |

### 12.2 Icon dự trữ (đã tải, chưa dùng)

| File | Figma name | Gợi ý dùng cho |
|------|-----------|----------------|
| `ic_home.svg` | Home | Tab home nếu đổi IA |
| `ic_timer.svg` | timer | Focus / đếm thời gian |
| `ic_progress.svg` | progress | Task / tiến độ |
| `ic_paper.svg` | Paper | Tài liệu / ghi chú |

### 12.3 Icon chưa tải nhưng có trong Figma Icon Family

Nếu cần thêm icon, dùng Figma MCP `get_design_context` với `fileKey=Z2puEDKMPEUvfZPRFw4NK7`, `nodeId=381:3605` để lấy toàn bộ catalog. Icon family gồm **~90 icon** bao phủ: Search, Folder, Wallet, Graph, Bookmark, Home, Notification, Chat, Heart, Paper (nhiều variant), Send, Password, Swap, Work, Scan, Activity, Calendar, Message, Video, Plus, Chart, Game, Bag, Ticket Star, More, Discount, Buy, Info Square, Danger, Close Square, Tick Square, Discovery, Location, Document, Setting, Time, Volume, Star, Camera, Profile, Add User, 2 User, 3 User, Login, Logout, Download, Upload, Voice, Delete, Edit, Play, Shield, Show/Hide, Filter, Image, Call, Lock/Unlock, Arrow (tất cả hướng), Card, Close, Car, More dots, Announcement, Gas, Check, wave, Trees, soundwave, arrow-bend, radio, pause.

### 12.4 Cách dùng trong Flutter

```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/icons/nav/ic_home.svg',
  width: 24,
  height: 24,
  colorFilter: ColorFilter.mode(
    StyleTokens.textPrimary, // tint bất kỳ màu nào
    BlendMode.srcIn,
  ),
)
```

---

*Tài liệu: file Figma Prodify = reference phong cách cho app khác; cập nhật khi đổi file nguồn hoặc khi team thống nhất token riêng cho sản phẩm.*
