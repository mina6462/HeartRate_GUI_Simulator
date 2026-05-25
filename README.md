💓 Heart Rate GUI Simulator

A MATLAB-based GUI application that interfaces with Arduino hardware to simulate and analyze heartbeat motion in real time.


Overview
This project combines embedded hardware with MATLAB software to simulate a heart rate monitor. An Arduino ultrasonic sensor captures motion data, which drives a servo motor to physically replicate heartbeat motion. A custom MATLAB GUI App visualizes the data in real time, applies regression modeling to predict future motion trends, and performs error analysis for accuracy validation.
Built using object-oriented programming principles and numerical methods for robust, maintainable code.

Tech Stack
CategoryTools / ComponentsSoftwareMATLAB App Designer, MATLAB OOPHardwareArduino, Ultrasonic Sensor (HC-SR04), Servo MotorMethodsNumerical Methods, Regression Modeling, Error AnalysisInterfaceSerial communication (Arduino ↔ MATLAB)

System Flow
[Ultrasonic Sensor]
        │
        ▼
   [Arduino UNO]  ──(Serial)──►  [MATLAB GUI App]
        │                               │
        ▼                               ▼
  [Servo Motor]                  [Live Plot + Regression]
 (heartbeat motion)              (data analysis & prediction)

Key Features

Real-Time GUI — Custom MATLAB App Designer interface displaying live heartbeat waveform
Hardware Integration — Arduino reads ultrasonic sensor data and controls servo motor for physical simulation
Regression Modeling — Applied curve fitting and regression to predict future motion patterns
Error Analysis — Quantified measurement accuracy using numerical error analysis techniques
OOP Architecture — Structured codebase using MATLAB classes for clean, modular integration


How to Run
Requirements

MATLAB (R2021a or later recommended) with App Designer
Arduino IDE
Arduino UNO board
HC-SR04 Ultrasonic Sensor
Servo Motor

Steps

Upload heartrate_sensor.ino to your Arduino via Arduino IDE
Connect the Arduino via USB and note the COM port
Open HeartRateGUI.mlapp in MATLAB App Designer
Update the serial port in the code to match your COM port
Run the app — sensor data will stream live into the GUI


Project Structure
heart-rate-gui-simulator/
├── arduino/
│   └── heartrate_sensor.ino     # Arduino sketch for sensor + servo
├── matlab/
│   └── HeartRateGUI.mlapp       # MATLAB GUI application
├── docs/
│   └── report.pdf               # Project report with error analysis
└── images/
    └── gui_screenshot.png       # GUI demo screenshot

Project Status
✅ Completed — September 2025 – December 2025

Media

📷 GUI screenshots and demo video coming soon


What I Learned

Bridging hardware (Arduino) and software (MATLAB) via serial communication
Designing user-friendly GUIs in MATLAB App Designer using OOP
Applying numerical methods and regression analysis to real sensor data
Validating system accuracy through structured error analysi
