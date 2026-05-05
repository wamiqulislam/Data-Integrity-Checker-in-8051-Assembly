# 🔐 File Integrity Checker (8051 Assembly + EEPROM)

A low-level embedded system project that detects file corruption or unauthorized modification using a **CRC-8 checksum algorithm**, implemented entirely in **8051 Assembly** and simulated in **Proteus**.

---

## 📌 Overview

This project simulates a **file integrity verification system** using:

* **AT89C51 (8051 microcontroller)**
* **External EEPROM (AT24C512 via I2C)**
* **Keypad input (4x3)**
* **LED indicators + buzzer**
* **7-segment display**

The system computes a checksum for a predefined data block (“file”), stores it in EEPROM, and later verifies integrity by recomputing and comparing.

---

## ⚙️ Core Features

### ✅ 1. CRC-8 Checksum Engine

* Polynomial: `x⁸ + x⁵ + x⁴ + 1` (0x31)
* Byte-by-byte + bitwise processing
* Entirely implemented in Assembly

---

### 💾 2. EEPROM Storage (I2C)

* Uses **AT24C512**
* Custom **bit-banged I2C protocol**
* Supports:

  * Write checksum to address
  * Read checksum from address

---

### 🔢 3. Keypad Interface

* 4x3 matrix keypad (Port 2)
* Controls:

  * `0–9` → Select memory index
  * `*` → Reset system
  * `#` → Execute (Store / Verify)

---

### 🔁 4. Dual Mode Operation

| Mode            | Description                              |
| --------------- | ---------------------------------------- |
| **STORE Mode**  | Computes checksum → stores in EEPROM     |
| **VERIFY Mode** | Computes checksum → compares with EEPROM |

Mode is controlled via:

```
P3.2 (MODE_SW)
HIGH → STORE
LOW  → VERIFY
```

---

### 💡 5. Visual Feedback System

| Indicator              | Meaning                      |
| ---------------------- | ---------------------------- |
| 🟡 Yellow LED          | Idle state                   |
| 🔵 Blue LED            | Successfully stored checksum |
| 🟢 Green LED           | Valid file (checksum match)  |
| 🔴 Red LED + 🔊 Buzzer | Corrupted file               |

---

### 🔢 6. 7-Segment Display

* Displays selected memory index (0–9)
* Displays `-` when no selection

---

## 🧠 How It Works

### Step-by-step flow:

1. User selects an ID (0–9)
2. Presses `#` to execute
3. System:

   * Computes CRC of internal data (`MY_FILE`)
4. Based on mode:

   * **STORE** → writes CRC to EEPROM
   * **VERIFY** → reads stored CRC and compares

---

## 🧩 Project Structure

```
File Integrity Checker/
│
├── Kiel asm/
│   ├── integrityEngine.asm     # Main assembly code
│   ├── Objects/                # Compiled HEX output
│   └── Listings/
│
├── Proteus/
│   ├── New Project.pdsprj      # Circuit design
│   └── .workspace files
│
└── README.md
```

---

## 🛠️ Hardware / Simulation Setup

### 🧾 Components Used

* AT89C51 Microcontroller
* AT24C512 EEPROM
* 4x3 Keypad
* 7-Segment Display (Common Anode)
* LEDs (Red, Green, Yellow, Blue)
* Buzzer
* Pull-up resistors (4.7kΩ for SDA/SCL)

---

### ⚠️ Important (Proteus Gotcha)

Without these, I2C will silently fail:

```
SDA → 4.7kΩ → VCC
SCL → 4.7kΩ → VCC
```

---

## 🚀 How to Run

### 1. Compile Code (Keil)

* Open `FIC project.uvproj`
* Build → generates `.hex` file

---

### 2. Load into Proteus

* Open `New Project.pdsprj`
* Double-click microcontroller
* Set:

```
Program File → ../Kiel asm/Objects/FIC project.hex
```

---

### 3. Run Simulation

---

## 🎮 Usage Instructions

### 🟡 Idle State

* Yellow LED ON
* Display shows `-`

---

### 🔢 Select ID

* Press any key `0–9`
* Number appears on 7-seg

---

### 💾 STORE Mode

* Set switch HIGH
* Press `#`
* Result:

  * Blue LED ON → Stored successfully

---

### 🔍 VERIFY Mode

* Set switch LOW
* Press `#`
* Results:

  * ✅ Green LED → File valid
  * ❌ Red LED + Buzzer → File corrupted

---

### 🔄 Reset

* Press `*`
* System returns to idle

---

## 📦 Internal Data ("File")

Defined inside assembly:

```
MY_FILE:
    DB 12h, 12h, 22h, ...
    ...
MY_FILE_END:
```

Checksum is computed over this entire block.

---

## 🧪 Testing Ideas

* Modify `MY_FILE` → causes checksum mismatch
* Store once, then tweak data → verify should fail
* Change EEPROM contents manually → simulate corruption

---

## 🔧 Technical Highlights

* Bit-level CRC implementation
* Software I2C (no hardware peripheral)
* Memory addressing (16-bit EEPROM)
* Modular assembly design
* Hardware-software co-design (Proteus + Keil)

---

## ⚡ Limitations

* Fixed internal file (not dynamic input)
* No error handling for I2C ACK
* Single-byte checksum (CRC-8)

---

## 🚀 Possible Improvements

* Upgrade to CRC-16 / CRC-32
* Add LCD instead of 7-seg
* Store multiple files / blocks
* Add UART logging
* Add password protection before verify/store

---

## 🧠 What You Learn From This

* Embedded system design from scratch
* Assembly-level memory manipulation
* Communication protocols (I2C)
* Data integrity concepts
* Hardware debugging in Proteus

---

## 📜 License

Free to use for learning and academic purposes.

---

## 👀 Final Note

This project is basically a **mini integrity engine at hardware level** — no OS, no libraries, just raw control.

Which is exactly why debugging it probably cost you your sanity 😄
