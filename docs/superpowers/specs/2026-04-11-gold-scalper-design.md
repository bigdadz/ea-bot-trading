# GoldScalper EA - Design Specification

## Overview

MQL5 Expert Advisor สำหรับ Scalping XAUUSD (Gold) บน Hedging Account ใช้ Multi-timeframe EMA Crossover + RSI Filter เป็นสัญญาณหลัก พร้อมระบบบริหารความเสี่ยงและฟีเจอร์เสริมครบครัน

## 1. Signal Logic

### Entry Conditions

**Buy:**
1. M15: EMA 50 > EMA 200 (uptrend)
2. M5: EMA 9 ตัดขึ้นเหนือ EMA 21 (golden cross)
3. M5: RSI(14) อยู่ระหว่าง RSI_Lower - RSI_Upper (ไม่ overbought)

**Sell:**
1. M15: EMA 50 < EMA 200 (downtrend)
2. M5: EMA 9 ตัดลงใต้ EMA 21 (death cross)
3. M5: RSI(14) อยู่ระหว่าง RSI_Lower - RSI_Upper (ไม่ oversold)

### Exit Conditions
- Take Profit (default 100 points)
- Stop Loss (default 50 points)
- Trailing Stop / Break Even (auto)
- สัญญาณตรงข้าม (optional, `CloseOnOppositeSignal`)

### Signal Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| EMA_Fast_Period | int | 9 | EMA เร็วบน M5 |
| EMA_Slow_Period | int | 21 | EMA ช้าบน M5 |
| EMA_Trend_Fast | int | 50 | EMA เร็วบน M15 |
| EMA_Trend_Slow | int | 200 | EMA ช้าบน M15 |
| RSI_Period | int | 14 | Period ของ RSI |
| RSI_Upper | int | 70 | ขอบบน RSI |
| RSI_Lower | int | 30 | ขอบล่าง RSI |
| TakeProfit | int | 100 | Take Profit (points) |
| StopLoss | int | 50 | Stop Loss (points) |
| CloseOnOppositeSignal | bool | true | ปิดออเดอร์เมื่อสัญญาณสวน |

## 2. Risk Management

### Lot Size Mode

ผู้ใช้เลือกได้ระหว่าง Fixed Lot หรือ % Risk ผ่าน `LotMode`

| Parameter | Type | Default | Description |
|---|---|---|---|
| LotMode | enum | FIXED | FIXED หรือ PERCENT |
| FixedLot | double | 0.01 | Lot คงที่ |
| RiskPercent | double | 1.0 | % ของ Balance ต่อออเดอร์ |

**คำนวณ Lot (PERCENT mode):**
```
LotSize = (Balance * RiskPercent / 100) / (StopLoss * TickValue)
```
Clamp ให้อยู่ระหว่าง broker min/max lot (`SymbolInfoDouble SYMBOL_VOLUME_MIN/MAX`)

### Order Limits

| Parameter | Type | Default | Description |
|---|---|---|---|
| MaxOpenOrders | int | 3 | ออเดอร์สูงสุดที่เปิดพร้อมกัน |
| MaxSpread | int | 30 | Spread สูงสุดที่ยอมรับ (points) |

### Max Daily Drawdown

| Parameter | Type | Default | Description |
|---|---|---|---|
| UseDailyDrawdown | bool | true | เปิด/ปิดระบบจำกัดขาดทุนรายวัน |
| MaxDailyDrawdownPercent | double | 3.0 | % ขาดทุนสูงสุดต่อวัน |
| MaxDailyDrawdownAction | enum | STOP | STOP (หยุดเทรด) หรือ CLOSE_ALL (ปิดทั้งหมดแล้วหยุด) |

**Logic:**
- บันทึก Balance ตอน 00:00 server time
- ติดตาม floating loss + realized loss ตลอดวัน
- เมื่อ drawdown >= MaxDailyDrawdownPercent → ทำตาม Action
- รีเซ็ตเมื่อขึ้นวันใหม่

## 3. Trailing Stop & Break Even

### Break Even

| Parameter | Type | Default | Description |
|---|---|---|---|
| UseBreakEven | bool | true | เปิด/ปิดระบบ Break Even |
| BreakEvenTrigger | int | 30 | กำไรกี่ points ถึง trigger |
| BreakEvenProfit | int | 5 | ล็อคกำไรกี่ points เหนือจุดเปิด |

**Logic:**
- Buy: ถ้า `Bid - OpenPrice >= BreakEvenTrigger` → SL = `OpenPrice + BreakEvenProfit`
- Sell: ถ้า `OpenPrice - Ask >= BreakEvenTrigger` → SL = `OpenPrice - BreakEvenProfit`
- ทำครั้งเดียวต่อออเดอร์ ไม่ย้ายกลับ

### Trailing Stop

| Parameter | Type | Default | Description |
|---|---|---|---|
| UseTrailingStop | bool | true | เปิด/ปิดระบบ Trailing Stop |
| TrailingStart | int | 40 | กำไรกี่ points ถึงเริ่ม trail |
| TrailingStep | int | 10 | ขยับ SL ทีละกี่ points |
| TrailingStop | int | 30 | ระยะห่างจากราคาปัจจุบัน (points) |

**Logic:**
- เริ่มเมื่อกำไร >= TrailingStart
- Buy: ถ้า `Bid - SL >= TrailingStop + TrailingStep` → SL = `Bid - TrailingStop`
- Sell: ถ้า `SL - Ask >= TrailingStop + TrailingStep` → SL = `Ask + TrailingStop`
- ขยับทิศทางเดียว ไม่ย้าย SL ถอยหลัง

### ลำดับการทำงาน
1. เช็ค Break Even ก่อน
2. ถ้า Break Even ทำแล้ว → เช็ค Trailing Stop
3. Trailing Stop override SL ของ Break Even เมื่อราคาวิ่งไกลพอ

## 4. Time Filter

| Parameter | Type | Default | Description |
|---|---|---|---|
| UseTimeFilter | bool | true | เปิด/ปิดระบบกรองเวลา |
| TradeStartHour | int | 8 | ชั่วโมงเริ่มเทรด (server time) |
| TradeStartMinute | int | 0 | นาทีเริ่มเทรด |
| TradeEndHour | int | 20 | ชั่วโมงหยุดเทรด |
| TradeEndMinute | int | 0 | นาทีหยุดเทรด |
| CloseOutsideTime | bool | false | ปิดออเดอร์ค้างเมื่อหมดเวลา |

**Logic:**
- ตรวจสอบเวลา server ทุก tick
- นอกช่วงเวลา → ไม่เปิดออเดอร์ใหม่
- ถ้า CloseOutsideTime = true → ปิดออเดอร์ค้างทั้งหมด
- Default 08:00-20:00 ครอบคลุม London + New York session

## 5. News Filter

| Parameter | Type | Default | Description |
|---|---|---|---|
| UseNewsFilter | bool | true | เปิด/ปิดระบบกรองข่าว |
| NewsMinutesBefore | int | 30 | หยุดเทรดกี่นาทีก่อนข่าว |
| NewsMinutesAfter | int | 15 | หยุดเทรดกี่นาทีหลังข่าว |
| NewsImpact | enum | HIGH | ระดับข่าว: HIGH, MEDIUM, ALL |
| CloseBeforeNews | bool | false | ปิดออเดอร์ค้างก่อนข่าว |

**วิธีดึงข่าว:**
- ใช้ MQL5 `CalendarValueHistory` (built-in Economic Calendar)
- กรองเฉพาะข่าว USD
- โหลดข่าววันนี้ตอนเริ่มวัน, refresh ทุก 1 ชั่วโมง

**Logic:**
- ก่อนเปิดออเดอร์ → เช็คว่ามีข่าวในช่วง NewsMinutesBefore
- ถ้ามีข่าว → ไม่เปิดออเดอร์ใหม่
- ถ้า CloseBeforeNews = true → ปิดออเดอร์ค้างก่อนข่าว
- หลังข่าวผ่าน NewsMinutesAfter → กลับมาเทรดปกติ

## 6. Dashboard

แสดงข้อมูลมุมซ้ายบนของ chart ด้วย `OBJ_LABEL` graphic objects

### ข้อมูลที่แสดง
| หมวด | รายละเอียด |
|---|---|
| EA Status | ON/OFF + เหตุผลถ้าหยุด (drawdown/news/time) |
| Account Info | Balance, Equity, Free Margin |
| Today P&L | กำไร/ขาดทุนวันนี้ (เงิน + %) |
| Daily Drawdown | Drawdown ปัจจุบัน / เพดาน |
| Open Orders | จำนวนออเดอร์ / สูงสุด |
| Spread | ปัจจุบัน / สูงสุดที่ยอมรับ |
| Trend (M15) | UP/DOWN + EMA 50, EMA 200 |
| Signal (M5) | BUY/SELL/WAIT + EMA 9, EMA 21, RSI |
| Next News | เวลาข่าวถัดไป + ชื่อข่าว |
| Time Filter | ช่วงเวลาเทรด + สถานะ IN/OUT |

### Render
- ใช้ `OBJ_LABEL` สร้าง text objects
- อัพเดททุก tick (ราคา) และทุก 1 วินาที (สถานะ)
- สี: เขียว = ปกติ, แดง = เตือน/หยุด, เหลือง = ระวัง

## 7. File Structure

```
ea-bot-trading/
├── Experts/
│   └── GoldScalper/
│       └── GoldScalper.mq5          # ไฟล์หลัก EA (orchestrator)
├── Include/
│   └── GoldScalper/
│       ├── SignalManager.mqh         # Signal logic (EMA + RSI)
│       ├── TradeManager.mqh          # เปิด/ปิด/จัดการออเดอร์
│       ├── RiskManager.mqh           # Lot calculation, daily drawdown
│       ├── TrailingManager.mqh       # Trailing Stop + Break Even
│       ├── TimeFilter.mqh            # Time Filter
│       ├── NewsFilter.mqh            # News Filter
│       ├── Dashboard.mqh             # Dashboard display
│       └── Defines.mqh               # Enums, constants, input params
└── docs/
    └── superpowers/
        └── specs/
            └── 2026-04-11-gold-scalper-design.md
```

### หลักการแบ่งไฟล์
- แต่ละ `.mqh` รับผิดชอบงานเดียว
- `GoldScalper.mq5` เป็น orchestrator เรียกใช้ manager ต่างๆ
- `Defines.mqh` รวม input parameters, enums, constants ไว้ที่เดียว

## 8. Execution Flow (OnTick)

```
OnTick()
├── Dashboard.Update()
├── TimeFilter.IsTradeAllowed()?
│   ├── NO → CloseOutsideTime? → ปิดออเดอร์ค้าง → return
│   └── YES ↓
├── NewsFilter.IsTradeAllowed()?
│   ├── NO → CloseBeforeNews? → ปิดออเดอร์ค้าง → return
│   └── YES ↓
├── RiskManager.IsDailyDrawdownExceeded()?
│   ├── YES → CLOSE_ALL? → ปิดออเดอร์ → return
│   └── NO ↓
├── TrailingManager.ManageOrders()  // Break Even + Trailing Stop
├── SignalManager.CheckSignal()
│   ├── BUY signal
│   │   ├── CloseOnOppositeSignal? → ปิด Sell ที่ค้าง
│   │   ├── MaxOpenOrders reached? → skip
│   │   ├── MaxSpread exceeded? → skip
│   │   └── RiskManager.CalculateLot() → TradeManager.OpenBuy()
│   ├── SELL signal
│   │   ├── CloseOnOppositeSignal? → ปิด Buy ที่ค้าง
│   │   ├── MaxOpenOrders reached? → skip
│   │   ├── MaxSpread exceeded? → skip
│   │   └── RiskManager.CalculateLot() → TradeManager.OpenSell()
│   └── NO signal → return
```
