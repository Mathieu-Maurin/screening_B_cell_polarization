//////////////////////////////////////////////////////
////// Macro 1: Extraction of cell-bead pairs ///////
////////////////////////////////////////////////////

/*
The purpose of this macro is to extract bead-cell pairs for the subsequent analysis
Works on composite images reconstructed with the following channels : 
Channel 1 : gamma-Tubulin
Channel 2 : Dapi
Channel 3 : Lamp1 
Channel 4 : Fluorescent beads

Raw image composites are in the format PlateName-Well_A01-Pos1,  
where A01 indicates the well coordinate in the plate and Pos1 the field 1 acquired in the well
For this dataset, 11 positions were acquired in each well.
*/


////////////////////////// Image J parameter /////////////////////////////////////////////////

run("Set Measurements...", "area mean min centroid center integrated redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black");

//////////////////////////////////////////////////////////////////////////////////////////////



///////////////////////////// Folder Management /////////////////////////////////////////////

/*
If mydatasPathway/FolderName is your data's folder, here it creates
mydatasPathway/FolderName_Extracted_Couple/Individual_Rois
mydatasPathway/FolderName_Extracted_Couple/Extraction_Masks
*/

dirdata = getDirectory("Plate composite directory");
dirsaving = substring(dirdata,0, lengthOf(dirdata)-1)+"_Extracted_Couple"+File.separator();
File.makeDirectory(dirsaving);
dir1=dirsaving+"Individual_Rois_and_Masks"+File.separator;
File.makeDirectory(dir1);
dir2=dirsaving+"Extraction_Masks"+File.separator;
File.makeDirectory(dir2);

///////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////// Extraction parameters ////////////////////////////////

/*
Enter the coordinates of the wells and positions to process (must have a single space in between each letter or number)
*/

Dialog.create("Couple bead cell extraction parameters");
Dialog.addString("Plate Name", "Rep1-Plate1", 25);
Dialog.addString("well letter to process", "B C D E F G", 25);
Dialog.addString("well line to process", "01 02 03 04 05 06 07 08 09 10 11", 25);
Dialog.addString("field to process", "1 2 3 4 5 6 7 8 9 10 11", 25);
Dialog.addNumber("Cell mask channel index",1, 0 , 8, "");
Dialog.addNumber("Beads channel index",4, 0 , 8, "");
Dialog.addNumber("Nuclei channel index",2, 0 , 8, "");
Dialog.addString("Cell thresholding method", "Li", 20);
Dialog.addString("Bead thresholding method", "Yen", 20);
Dialog.addString("Nucl thresholding method", "Yen", 20);
Dialog.show(); 
PlateName =Dialog.getString();
LetterText=Dialog.getString();
LinesText=Dialog.getString();
FieldText=Dialog.getString();
cellChan = Dialog.getNumber();
beadChan = Dialog.getNumber();
nuclChan = Dialog.getNumber();
ThreshCell = Dialog.getString();
ThreshBead = Dialog.getString();
ThreshNucl = Dialog.getString();


LetterArray=split(LetterText, " \t\n\r"); // split the text from the dialog box
LineArray=split(LinesText, " \t\n\r");
FieldArray=split(FieldText, " \t\n\r");

////////////////////////////////////////////////////////////

if(isOpen("Log")) {
	selectWindow("Log");
	run("Close");
}

///////////// Extraction of cell-bead pairs ////////////////

setBatchMode(true);

for (i=0 ; i<LetterArray.length ; i++) {
	Letter=LetterArray[i];
	for (j=0 ; j<LineArray.length ; j++) {
		Line=LineArray[j];
		for (k=0; k<FieldArray.length; k++) {
		Field=FieldArray[k];
		name=PlateName+"-Well_"+Letter+Line+"-Pos"+Field+".tif";
		if(File.exists(dirdata+name)) {
		open(dirdata+PlateName+"-Well_"+Letter+Line+"-Pos"+Field+".tif");
		run("Stack to Hyperstack...", "order=xyczt(default) channels=4 slices=1 frames=1 display=Grayscale");


		roiManager("reset");
		run("Clear Results");

		/// make cell mask and add the nucleus mask to fill them properly ///

		selectWindow(name);
		run("Duplicate...", "title=tempMaskCell.tif duplicate channels="+cellChan+"");
		run("8-bit");
		run("Auto Threshold", "method="+ThreshCell+" white");
		
		selectWindow(name);
		run("Duplicate...", "title=tempMaskNucl.tif duplicate channels="+nuclChan+"");
		run("8-bit");
		run("Auto Threshold", "method="+ThreshNucl+" white");
		
		imageCalculator("OR create", "tempMaskCell.tif","tempMaskNucl.tif");
		selectWindow("tempMaskCell.tif");
		run("Close");
		selectWindow("tempMaskNucl.tif");
		run("Close");
		selectWindow("Result of tempMaskCell.tif");
		rename("tempMaskCell.tif");
		run("Make Binary");

		///////////////////////////////////////////////////////////////////
		
		run("Analyze Particles...", "size=500-10000 pixel circularity=0.00-1.00 show=Masks exclude clear"); /// first cleaning to remove too big clusters of cells
		selectWindow("tempMaskCell.tif");
		run("Close");

		selectWindow("Mask of tempMaskCell.tif");
		run("Grays");
		rename("tempMaskCell.tif");
		run("Watershed");
		run("Analyze Particles...", "size=500-3000 pixel circularity=0.30-1.00 show=Masks exclude clear add"); /// cell detection after watershed
		CellCounts=roiManager("Count");

		selectWindow("Mask of tempMaskCell.tif");
		run("Grays");
		saveAs("Tiff", dir2 +PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_CellMask.tif");
		
		if (CellCounts==0) {
				print("No cell detected for "+Letter+Line+"-Pos"+Field);
				run("Close All");
		} else { /// if cell detected
				roiManager("Save", dir2+PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_RoiSetCells.zip");
				roiManager("reset");
				/// Make bead mask
				selectWindow(name);
				run("Duplicate...", "title=tempBeads.tif duplicate channels="+beadChan+"");
				selectWindow("tempBeads.tif");
				run("8-bit");
				run("Auto Threshold", "method="+ThreshBead+" white");
				run("Analyze Particles...", "size=10-500 pixel circularity=0.00-1.00 show=Masks exclude clear add");
				
				selectWindow("Mask of tempBeads.tif");
				run("Grays");
				saveAs("Tiff", dir2 +PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_BeadsMask.tif");
				
				selectWindow("tempBeads.tif");
				run("Close");
				
				BeadsCounts=roiManager("Count");
				if (BeadsCounts==0) {			
					print("No beads detected for "+Letter+Line+"-Pos"+Field);
					run("Close All");
				} else {
					roiManager("Save", dir2+Letter+Line+"_s"+Field+"RoiSetBeads.zip");
					roiManager("reset");
					
					run("Clear Results");
					
					roiManager("Open",dir2+PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_RoiSetCells.zip");
					selectWindow(PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_BeadsMask.tif"); /// measure for each cell on the bead mask
					roiManager("Measure");
			
					cellIndex=0;
					for(cell=0;cell<nResults();cell++) {
						Xcell=getResult("X",cell); //////// measure the centroid of the choosen cell
						Ycell=getResult("Y",cell); //////// measure the centroid of the choosen cell
						if(getResult("RawIntDen", cell)>(255*3)) { /// more than 3 pixels of bead mask
								Xbead=getResult("XM",cell); /// center of mass = centroid of the bead mask
								Ybead=getResult("YM",cell); /// center of mass = centroid of the bead mask
								deltax=Xcell-Xbead;
								deltay=Ycell-Ybead;
								distance=sqrt(deltay*deltay+deltax*deltax);
								areaCell=getResult("Area", cell);
								rayonCell=sqrt(areaCell/3.14116); /// estimate the radius of the cell
								if (distance>0.5*rayonCell && distance<2*rayonCell) { /// select cells with beads that are on one side
									selectWindow(name);
									roiManager("select", cell);
									run("Duplicate...", "title=temp duplicate channels=1-4");
									saveAs("Tiff",dirsaving+PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_Cell"+cellIndex+".tif");
									
									selectWindow(PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_BeadsMask.tif");
									roiManager("select", cell);
									run("Duplicate...", "title=temp duplicate");
									run("Clear Outside");
									saveAs("Tiff",dir1+PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_Cell"+cellIndex+"_beadMask.tif");
									
									selectWindow(PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_CellMask.tif");
									roiManager("select", cell);
									run("Duplicate...", "title=temp duplicate");
									run("Clear Outside");
									saveAs("Tiff",dir1+PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_Cell"+cellIndex+"_cellMask.tif");
									
									
									roiManager("Save Selected" , dir1+PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_Cell"+cellIndex+".zip");
									   
									cellIndex=cellIndex+1;
								}
								
						}
					}
					if(cellIndex==0) {
						print("No couple detected for "+Letter+Line+"-Pos"+Field);
					}
					
					run("Close All");
					
				} /// if beads were detected
		} /// if cells were detected
		} /// if position exists
		} /// Field
	}	/// Line
} /// Letter

setBatchMode(false);

if(isOpen("Log")) {
	selectWindow("Log");
	saveAs("Text",dirsaving+"Extraction_Log.txt");
	run("Close");
}
