########################## screening_B_cell_polarization #######################################

Those are ImageJ macros to analyse B cell polarity by measuring mtoc or lysosomes postion inside a B cell in contact with a presenting antigen bead.
Comments are available inside macro code to understand the parameters.
To use the macros you need to put in one directory composite images reconstructed with the following channels 
Channel 1 : gamma-Tubulin
Channel 2 : Dapi
Channel 3 : Lamp1 
Channel 4 : Fluorescent beads

Composites images must be in a format PlateName-Well_A01-Pos1 
where A01 indicates the well coordinate in the plate and Pos1 the field 1 acquired in the well
Composites must be store in a directory to select for analysis

#####################################################################################################################

#######################################
Macro_1_cell_beads_couple_extraction.ijm :

The purpose of this macro is to extract bead-cell pairs for the subsequent analysis
Works on composite images reconstructed with the following channels : 
Channel 1 : gamma-Tubulin
Channel 2 : Dapi
Channel 3 : Lamp1 
Channel 4 : Fluorescent beads

Raw image composites are in the format PlateName-Well_A01-Pos1,  
where A01 indicates the well coordinate in the plate and Pos1 the field 1 acquired in the well
Composites must be store in a directory to select for analysis
#######################################

#######################################
Macro_2_polarity_analysis.ijm:

The purpose of this macro is to measure the centrosome and lysosome polarity indexes for each bead-cell pair.
Works on composite images reconstructed with the following channels : 
Channel 1 : gamma-Tubulin
Channel 2 : Dapi
Channel 3 : Lamp1 
Channel 4 : Fluorescent beads

Raw image composites are in the format PlateName-Well_A01-Pos1,  
where A01 indicates the well coordinates in the plate and Pos1 the field 1 acquired in the well
Works after Macro 1
#######################################

#######################################
Macro_3_normalise_and_concatenate_tables.ijm :

The purpose of this macro is to normalize data and concatenate tables. It works after Macro 2. 
Output tables are in the format PlateName-Well_A01_Results. A01 indicates the well coordinate in the plate. It contains all the polarity results from all positions of a given well. The macro concatenates and normalizes data to get a single table for centrosome-polarity or lysosomes-polarity. It computes also median values for each well. Normalization is based on the median value of well B01 of each plate (non-targeting siRNA), which is normalized to 1. 
#######################################

