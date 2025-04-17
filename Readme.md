# Digital Logic Design Project: FPGA Car Parking System

## 1. Introduction

This project implements a Car Parking System using SystemVerilog/VHDL for the Terasic DE10-Lite FPGA board. It simulates the entry and exit logic of a parking lot, tracks available spaces, and potentially handles token-based entry/exit. This project was developed as part of a third-year Software Engineering digital logic design course.

## 2. Hardware Requirements

* **FPGA Board:** Terasic DE10-Lite (Intel MAX 10 FPGA)

## 3. Software Requirements

* **Design Software:** Intel Quartus Prime (Version specific to your setup, e.g., Lite Edition 20.1)
* **Simulation Software (Optional):** ModelSim or equivalent

## 4. Project Description & Features

This system manages a car park with a limited number of spaces. Key features include:

* **Entry Detection:** Senses vehicles entering the parking lot (using `entry_sensor` and `entry_btn_raw`).
* **Exit Detection:** Senses vehicles leaving the parking lot (using `exit_sensor` and `exit_btn_raw`).
* **Space Counting:** Tracks the number of available parking spaces.
* **Display:** Shows relevant information (e.g., available spaces, system state) on the DE10-Lite's 7-segment displays (`HEX0` to `HEX5`).
* **Token System (Potential):** May include logic for validating entry/exit tokens (`token_input`, `token_code`).
* **System State Display:** Indicates the current operational state (`state`).
* **Reset Functionality:** Allows resetting the system state (`reset`).

## 5. System Architecture (Modules)

The design is hierarchical, with the main module being `parking_system`[cite: 6]. Key sub-modules likely include:

* `clk_div`: Clock divider/generator[cite: 39].
* `db_entry`: Debouncer for entry button/sensor[cite: 28].
* `db_exit`: Debouncer for exit button/sensor[cite: 17].
* *(Add other modules described in your VHDL/Verilog files, e.g., counter, FSM, display driver, token logic)*

## 6. Inputs and Outputs

Based on the pin assignments (`carpark_partition_pins.json`), the top-level module (`parking_system`) has the following I/O:

* **Inputs:**
    * `clk_50MHz`: System clock input.
    * `reset`: Asynchronous or synchronous reset.
    * `entry_sensor`: Signal indicating a car at the entrance.
    * `exit_sensor`: Signal indicating a car at the exit.
    * `entry_btn_raw`: Raw input from an entry button.
    * `exit_btn_raw`: Raw input from an exit button.
    * `token_input[4:0]`: Input for parking token code.
* **Outputs:**
    * `HEX0[6:0]` to `HEX5[6:0]`: Outputs for the six 7-segment displays.
    * `state[3:0]`: Output indicating the current system state.
    * `token_code[4:0]`: Output related to token processing or display.
    * *(Add any other outputs like LEDs, control signals for barriers, etc.)*

## 7. How to Compile and Run

1.  **Open Project:** Launch Intel Quartus Prime and open the `carpark.qpf` project file.
2.  **Compile:** Run a full compilation (Processing -> Start Compilation). Ensure there are no critical errors.
3.  **Pin Assignments:** Verify pin assignments in the Pin Planner match the DE10-Lite board specifications (check against `carpark_partition_pins.json` and the board manual if needed). The project seems to already have pin assignments defined.
4.  **Program Device:**
    * Connect the DE10-Lite board via USB Blaster.
    * Open the Programmer (Tools -> Programmer).
    * Ensure the `.sof` file (located in the `output_files` directory after compilation) is selected.
    * Click "Start" to program the FPGA.
5.  **Test:** Use the switches (`token_input`?), buttons (`entry_btn_raw`, `exit_btn_raw`, `reset`?), and observe the 7-segment displays (`HEX0`-`HEX5`) to test the functionality based on sensor inputs.

## 8. Author

* [Your Name] - Third Year Software Engineering Student

---

Remember to replace placeholders like `[Your Name]` and add more specific details about your design choices, Finite State Machines (FSMs), counter logic, and any unique features you implemented. Good luck!
