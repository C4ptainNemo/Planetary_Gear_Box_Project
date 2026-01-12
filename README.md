# Planetary Gear Box Project
<img width="2849" height="2179" alt="gearbox" src="https://github.com/user-attachments/assets/b59eb78c-e1f0-4e7f-aee3-80b4d8b56f10" />
A Two Stage Compound Planetary Gearbox designed and built for a university design project. All content contained here was done by myself unless otherwise specified.

The project required a gearbox that would output 20 Nm of torque and have a 65x speed reduction. This was a group project done with three others, however I did all of the CAD except for some of the technical drawings (though I have included here my own versions).

I wrote a MATLAB script to help find a solution that optimised the design to have the minimum sized gearbox. The limiting factor in the size was the minimum advised gear module (1.5) using laminated lasercut acrylic to form the gears. I will note that the code isn't very good and required some adjustment of the solution that the main script output, but it gave a decent solution that was mostly the smallest it could possibly be. The search isn't very exhaustive either, and the checks for the validity of a solution are not very compregensive nor easy to update.

My individual design is similar to the final group version that was built, with the second stage of the individual design being the same as both stages on the group design. Referencing the appendix in the individual report shows the calculations used for the individual and group gearbox.

The process of designing and building the gearbox involved:  
  1. Calculations to solve for the sun gear module of a stage (which dictated the other gear modules), given various parameters such as output torque, input speed, teeth count of all gears, factor of safety, etc.  
  2. Writing the MATLAB scripts to find a solution that minimised the size of the gearbox.  
  3. 3D printing all the parts of the gearbox, including shafts and gears to validate assembly and function, and to inform any changes that were needed.  
  4. Manufacturing the non-3D printed parts and 1-for-1 swapping them for their 3D printed counterparts.  
