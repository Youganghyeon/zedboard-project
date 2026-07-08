# 🎮 Tetromino (Tetris) Game Development Project

하드웨어(FPGA/Verilog 등) 또는 임베디드 환경에서 작동하는 테트리스 게임 개발 로드맵 및 기능 명세서입니다.

---

## 📌 Development Roadmap (진행 상황)

- [x] **STEP 1: 블록 자동 하강 (Block Fall)**
  - 블록이 일정 주기로 아래로 떨어지는 로직 구현 완료.
- [x] **STEP 2: 좌우 이동 기능 (Move Left/Right)**
  - 버튼 입력을 감지하여 블록을 좌/우로 이동하는 제어 로직 구현 완료.
- [ ] **STEP 3: 다양한 블록 형태 구현 (Various Shapes)**
  - 기본 테트로미노 형태 구현 (`I`, `O`, `T`, `S` 미노 배열 설계 필요).
- [ ] **STEP 4: 블록 회전 기능 (Change Angle)**
  - 버튼 입력을 통해 블록의 방향을 90도씩 회전하는 로직 구현.
- [x] **STEP 5: 새로운 블록 생성 (Add Block)**
  - 기존 블록이 바닥에 닿으면 새로운 블록을 상단에 생성하는 로직 구현 완료.
- [ ] **STEP 6: 블록 쌓기 및 고정 (Lock Down)**
  - 바닥이나 다른 블록 위에 안착했을 때, 움직이지 않고 고정(Stack)되는 격자(Grid) 데이터 처리.
- [ ] **STEP 7: 라인 삭제 (Remove Line)**
  - `IsFull_Line == 1` 검사 로직 구현.
  - 💡 *구현 포인트:* 가장 아래 라인(Bottom)부터 한 줄씩 위로 올라가며 모든 라인을 전수 검사(Check)하고, 채워진 라인은 삭제 후 위쪽 블록들을 아래로 시프트(Shift).
- [ ] **STEP 8: 점수 시스템 (Add Point)**
  - 라인 삭제 개수에 따른 스코어 카운터 구현.
- [ ] **STEP 9: 난이도 조절 및 속도 가속 (Speed Control)**
  - 게임이 진행될 수록 떨어지는 속도가 빨라지는 시스템.
  - 💡 *하드웨어 최적화 팁:* 기존 상수(parameter)로 선언된 `BOX_X`, `BOTTOM`, `BOX_SIZE` 등을 레지스터(`reg`) 변수로 변경하여 가변적인 속도 제어 가능성 검토.

---

## 🎛️ Input Buttons Specification (버튼 입력 정의)

게임 컨트롤을 위해 **총 4개 이상의 입력 버튼**이 필요하며, 사용하지 않는 유휴 버튼은 속도(난이도) 조절용으로 할당합니다.

1. **⬅️ Left Button:** 블록 좌측 이동
2. **➡️ Right Button:** 블록 우측 이동
3. **🔄 Rotation Button:** 블록 각도 변경 (90도 회전)
4. **⚡ Speed/Option Button (남는 버튼 활용):** - 낙하 속도 수동 조절 또는 디버깅용 속도 가속(Soft Drop/Hard Drop) 기능 연동.

---

## 🛠️ Tetromino Shapes To Implement (구현 대상 블록)
현재 계획된 핵심 테트로미노 형상 리스트입니다.
* **I-Mino** (일자형)
* **O-Mino** (네모형)
* **T-Mino** (T자형)
* **S-Mino** (번개형)
