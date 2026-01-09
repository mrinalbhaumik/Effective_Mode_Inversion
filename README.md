# PSO Layered Model Inversion

## Overview

This MATLAB script performs Particle Swarm Optimization (PSO) to invert layered velocity models using phase velocity data. It reads input data from an Excel file, preprocesses it, and runs PSO with optional refinement stages to improve the inversion results.

---

## How to Use

### Step 1: Prepare your input data

* Place your input file (e.g., `Target curve- HVL_10m.xlsx`) in the working directory.
* The Excel file should contain two/three columns:

  1. Frequency (`w`)
  2. Phase velocity (`v_f`)
  3. Standard deviation (`v_std`) (optional)

### Step 2: Configure parameters (at the top of `PSO_main.m`)

* Modify parameters such as:

  * `Trial_num` — range of trial runs per layer count.
  * `Max_itr` — max iterations for initial PSO run.
  * `SwarmCount` — number of particles in the swarm.
  * `Tolerance` and `Tolerance_iteration` — convergence criteria.
  * `continueRefinement` — enable or disable refinement runs.
  * `Refinement_runs` — number of refinement iterations.
  * `Refinement_itr` — max iterations per refinement run.
  * `RunType` — `'manual'` (prompts user to continue after each run) or `'auto'` (runs all refinements automatically).

### Step 3: Run the script

* Simply run `PSO_Input.m` in MATLAB.
* The script will:

  * Preprocess the data.
  * Create a folder named after the input file (if not existing).
  * Run initial PSO inversion.
  * Optionally prompt for continuing with refinement runs.
  * Save results for each trial and layer count.

### Step 4: View results

* Results are saved in the folder named after your input file.
* `.mat` files contain inversion parameters and results.
* Plots during PSO show error bars for phase velocity and PSO progress.

---

## Notes

* The PSO progress plot shows live iteration status and allows stopping or pausing the run.
* Use the `RunType` parameter to control whether you want to manually confirm continuation or run refinements automatically.
* Ensure you have MATLAB Parallel Computing Toolbox for parallel PSO execution (`UseParallel` option).

---

## Contact

For questions or support, please contact:

[Mrinal bhaumik]
Email: [mrinal.bhaumik2012@gmail.com](mailto:mrinal.bhaumik2012@gmail.com)

---
