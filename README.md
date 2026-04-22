Command to start application: `Gear_Model`

*Note:* The Python based version of the application is under development

# GEAR MODEL
The application built in MATLAB serves as a tool for building the exact theoretical gear tooth geometry during the hobbing and MAAG shaping method manufacturing process.

Gear Model is a comprehensive MATLAB-based application designed to generate the exact theoretical gear tooth geometries of both involute and cycloidal profiles. The software achieves this by mathematically simulating actual manufacturing processes, specifically rack-cutter hobbing and MAAG shaping. Developed as an own student project within the academic framework of the Faculty of Mechanical Engineering at Brno University of Technology, this project serves as a kinematic and geometric analysis tool. It highlights that the fundamental law of gearing can be satisfied by alternative profile shapes (such as cycloidal gears) alongside the standard involute profiles.

Tested on MATLAB: R2025b

## Key Features
1. Advanced Profile Generation: Calculates mathematically exact tooth profiles for involute gears and cycloidal gears.

2. Manufacturing Simulation: Models the generation of gears through simulated hobbing and MAAG shaping using trapezoidal and cycloidal basic racks.

3. Kinematic Animation: Provides active, frame-by-frame animations of gear meshing and the rack-cutter hobbing process.

4. Extensive Export Options: Export geometries as 2D coordinate sets in TXT, CSV, XLSX (Excel), or PTS (Creo) formats.

5. Export static graphical plots (PNG, JPEG, PDF, SVG) and dynamic animations as GIF, AVI, or MP4 video files.

6. Multi-Language Support: The UI is fully localized and can be dynamically switched between English (EN), Slovak (SK), and Czech (CZ) with a smooth implementation of other langugages.

## Project Architecture
The application is built using MATLAB's App Designer and follows an Object-Oriented Programming (OOP) paradigm. The codebase is divided into clear logical modules:

- Core Generators: `involuteToothing` and `cycloidToothing`: Handle the core mathematical generation of the gear profiles based on input parameters (module, teeth, profile shift, etc.).

- `trapezoidalRack` and `cycloidRack`: Define the cutting tool geometries.

- Animation & Simulation Control: `animationControl`: Manages the transformation matrices, rotational frequencies, and plotting logic required to animate gear meshes and the hobbing process.

- `animationGraphicalAdditions`: Controls the visualization of significant circles, line styles, and action lines during the animation.

- Localization Utils: Scripts like `languageUtils`, `outerLanguageFun`, `profileTabLanguageFun`, and `animationTabLanguageFun` handle the dynamic loading of localized text files based on the user's selected language.

- UI Utilities: Auxiliary classes like `homeUtils` and `animationTabUtils` manage the layout, responsiveness, and component callbacks of the App Designer GUI.

## Usage
The application features an intuitive graphical user interface.

1. Open MATLAB and run the main application file.

2. Select your preferred language on the Home tab.

3. Navigate to the Profile tab to define static gear parameters and visualize individual or parametric sequences of gear teeth.

4. Navigate to the Animation tab to define center distances, backlash, or profile shifts, and run a real-time kinematic simulation of the gear mesh.

5. Use the export panel to record the simulation or save the geometric data.

## Contributing
This project was built primarily for geometric acquisition and gear meshing simulation. While the core mathematical models are highly accurate, the software architecture may have room for optimization, with some bugs being still present within the application.
Contributions, bug reports, and refactoring proposals are highly welcome! Feel free to open an issue or submit a pull request if you would like to improve the application.

*This project is licensed under the MIT License. See the LICENSE file for more details.*
