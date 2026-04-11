# ATR-Based Dynamic SL/TP/Trailing Design Spec

## Problem Statement

จาก backtest 7 รอบพบว่า:
- **Run 1-5:** 0 trades เพราะค่า SL/TP คงที่ไม่เหมาะกับ POINT=0.001 ของ Exness
- **Run 6:** 216 trades, +$17.33 (PF=1.30, WR=48%) — tight stops ได้กำไรเล็กน้อย
- **Run 7:** 216 trades, -$17.88 (PF=0.96, WR=61.57%) — **win rate ดีแต่ขาดทุน**

ปัญหาหลักของ Run 7: ค่า trailing/BE คงที่ตัดกำไรเร็วเกินไป
- Average Win = $3.00 (จาก TP ที่ตั้ง $10.00 — trailing ตัดก่อนถึง)
- Average Loss = $5.02 (โดน SL เต็มจำนวน)
- R:R จริง = 0.6:1 ทั้งที่ตั้งไว้ 2:1

## Solution

แทนที่ค่า SL/TP/Trailing คงที่ด้วยการคำนวณจาก ATR (Average True Range) ที่ปรับตัวตามความผันผวนจริงของตลาด

## Design

### 1. ATR Indicator Integration

**ตำแหน่ง:** `SignalManager.mqh`

เพิ่ม ATR indicator handle บน M5 timeframe (เข้ากับ indicator handles ที่มีอยู่แล้ว — EMA, RSI)

**Input ใหม่:**
```mql5
input int InpAtrPeriod = 14;  // ATR Period
```

**Method ใหม่:**
```
double GetATR()  // return ATR value in price (e.g. 3.500 = $3.50)
```

**ค่า ATR ตัวอย่างบน XAUUSD M5(14):**
| ช่วงเวลา | ATR โดยประมาณ |
|-----------|---------------|
| Asian (เงียบ) | $1.50 - $3.00 |
| London (ปกติ) | $3.00 - $5.00 |
| US session (แรง) | $5.00 - $10.00+ |

### 2. Dynamic SL/TP Mode

**Input ใหม่ใน Defines.mqh:**
```mql5
enum ENUM_SLTP_MODE
{
   SLTP_FIXED = 0,  // Fixed Points
   SLTP_ATR   = 1   // ATR-Based
};

input ENUM_SLTP_MODE InpSlTpMode        = SLTP_ATR;  // SL/TP Mode
input double         InpAtrSlMultiplier  = 1.5;       // ATR SL Multiplier
input double         InpAtrTpMultiplier  = 3.0;       // ATR TP Multiplier
```

**การคำนวณ:**
- SL (points) = ATR / SYMBOL_POINT * InpAtrSlMultiplier
- TP (points) = ATR / SYMBOL_POINT * InpAtrTpMultiplier
- เมื่อ mode = SLTP_FIXED → ใช้ InpStopLoss / InpTakeProfit เดิม

**ตัวอย่าง (ATR = $3.00, POINT = 0.001):**
- SL = 3.000 / 0.001 * 1.5 = 4500 points ($4.50)
- TP = 3.000 / 0.001 * 3.0 = 9000 points ($9.00)
- R:R = 1:2

**Safety Guard:**
- ถ้า SL < SYMBOL_TRADE_STOPS_LEVEL + spread + 10 → ใช้ STOPS_LEVEL + spread + 10 เป็น minimum
- TP ใช้ minimum เดียวกัน
- ป้องกัน "invalid stops" ในช่วงตลาดเงียบมาก

**ไฟล์ที่แก้:** `GoldScalper.mq5` — คำนวณ SL/TP ก่อนส่งเข้า `TradeManager.OpenBuy/OpenSell` (TradeManager ไม่ต้องแก้ — รับ slPoints/tpPoints เหมือนเดิม, ValidateStops ยังทำงานปกติ)

**Flow ใน GoldScalper.mq5:**
```
if(InpSlTpMode == SLTP_ATR)
{
   double atr = signalMgr.GetATR();
   slPoints = (int)(atr / point * InpAtrSlMultiplier);
   tpPoints = (int)(atr / point * InpAtrTpMultiplier);
}
else
{
   slPoints = InpStopLoss;
   tpPoints = InpTakeProfit;
}
tradeMgr.OpenBuy(lotSize, slPoints, tpPoints);
```

### 3. Dynamic Trailing & Break-Even

**Input ใหม่ใน Defines.mqh:**
```mql5
input double InpAtrBeMultiplier         = 1.5;  // ATR BE Trigger Multiplier
input double InpAtrBeProfitMultiplier   = 0.3;  // ATR BE Profit Multiplier
input double InpAtrTrailStartMultiplier = 2.0;  // ATR Trail Start Multiplier
input double InpAtrTrailStopMultiplier  = 1.0;  // ATR Trail Distance Multiplier
input double InpAtrTrailStepMultiplier  = 0.5;  // ATR Trail Step Multiplier
```

**ตัวอย่าง (ATR = $3.00):**

| Parameter | Fixed (เดิม) | ATR Mode |
|-----------|-------------|----------|
| BE Trigger | $3.00 คงที่ | ATR x 1.5 = $4.50 |
| BE Profit | $0.50 คงที่ | ATR x 0.3 = $0.90 |
| Trail Start | $4.00 คงที่ | ATR x 2.0 = $6.00 |
| Trail Distance | $3.00 คงที่ | ATR x 1.0 = $3.00 |
| Trail Step | $1.00 คงที่ | ATR x 0.5 = $1.50 |

**ทำไมถึงแก้ปัญหา Run 7:**

Run 7 ล้มเหลวเพราะ Trail Start=$4, Trail Distance=$3 → ราคาขึ้น +$5 แล้วกลับตัว ถูก trail ออกที่ +$2 (กำไรแค่ $2)

ATR Mode: Trail Start = ATR x 2 = $6 → ราคาต้องวิ่ง +$6 ก่อนเริ่ม trail, ให้ room มากขึ้น

**Dynamic ATR (ไม่ fix ตอนเข้า trade):**
- ตลาดเงียบลง → trail แคบขึ้น → ล็อกกำไรเร็ว (ดี)
- ตลาดผันผวนขึ้น → trail กว้างขึ้น → ไม่โดน stop จาก noise (ดี)
- ไม่ต้อง store ATR per position → โค้ดง่าย

**ไฟล์ที่แก้:** `TrailingManager.mqh` — method `Manage()` รับ ATR parameter

**Flow:**
```
if(InpSlTpMode == SLTP_ATR)
{
   double atr = signalMgr.GetATR();
   trailingMgr.Manage(atr);  // คำนวณ BE/Trailing จาก ATR ภายใน
}
else
{
   trailingMgr.Manage(0);    // ใช้ค่า fixed จาก input เดิม
}
```

### 4. Architecture Summary

**OnTick Flow ใหม่:**
```
1. Time Filter → block if outside trading hours
2. News Filter → block if near USD news
3. Daily Drawdown → block if loss limit exceeded
4. ATR = SignalManager.GetATR()              ← NEW
5. Trailing/BE management (ATR-based)        ← MODIFIED
6. Signal detection (ไม่เปลี่ยน)
7. ถ้ามี signal:
   ├─ คำนวณ SL/TP จาก ATR (ถ้า ATR mode)    ← NEW
   ├─ คำนวณ lot (ใช้ dynamic SL)
   └─ เปิด trade
8. Dashboard update (แสดง ATR + dynamic SL/TP) ← MODIFIED
```

**ไฟล์ที่แก้ไข (5 ไฟล์):**

| ไฟล์ | การเปลี่ยนแปลง |
|------|---------------|
| `Defines.mqh` | เพิ่ม `ENUM_SLTP_MODE` + input ใหม่ 9 ตัว |
| `SignalManager.mqh` | เพิ่ม ATR handle + `GetATR()` |
| `TrailingManager.mqh` | `Manage(atr)` คำนวณ BE/Trailing dynamic |
| `GoldScalper.mq5` | คำนวณ SL/TP จาก ATR + ส่ง ATR เข้า TrailingManager |

**ไฟล์ที่ไม่แตะ (4 ไฟล์):**
- `TradeManager.mqh` — รับ slPoints/tpPoints เหมือนเดิม, ValidateStops ยังทำงานปกติ
- `RiskManager.mqh` — รับ SL เป็น points เหมือนเดิม
- `TimeFilter.mqh` — ไม่เกี่ยว
- `NewsFilter.mqh` — ไม่เกี่ยว

### 5. Backward Compatibility

- Default mode = `SLTP_ATR`
- สลับกลับ `SLTP_FIXED` ได้ทุกเมื่อ → ใช้ InpStopLoss/InpTakeProfit/InpBreakEvenTrigger ฯลฯ เดิม
- Input เก่าทั้งหมดยังอยู่ ไม่ลบ ไม่เปลี่ยน default

### 6. Dashboard Changes

แสดงข้อมูลเพิ่ม:
- `ATR: $3.50`
- `SL/TP Mode: ATR`
- `Dynamic SL: $5.25 | TP: $10.50`

### 7. New Input Parameters Summary

| Input | Type | Default | กลุ่ม |
|-------|------|---------|-------|
| InpAtrPeriod | int | 14 | Signal |
| InpSlTpMode | ENUM_SLTP_MODE | SLTP_ATR | Signal |
| InpAtrSlMultiplier | double | 1.5 | Signal |
| InpAtrTpMultiplier | double | 3.0 | Signal |
| InpAtrBeMultiplier | double | 1.5 | Break Even |
| InpAtrBeProfitMultiplier | double | 0.3 | Break Even |
| InpAtrTrailStartMultiplier | double | 2.0 | Trailing |
| InpAtrTrailStopMultiplier | double | 1.0 | Trailing |
| InpAtrTrailStepMultiplier | double | 0.5 | Trailing |

รวม 9 inputs ใหม่ (จากเดิม 36 → 45)
