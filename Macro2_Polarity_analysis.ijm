////////////////////////////////////////////////////////
////// Macro 2: Measurement of Polarity Indexes ///////
//////////////////////////////////////////////////////

/*
The purpose of this macro is to measure the centrosome and lysosome polarity indexes for each bead-cell pair.
Works on composite images reconstructed with the following channels : 
Channel 1 : gamma-Tubulin
Channel 2 : Dapi
Channel 3 : Lamp1 
Channel 4 : Fluorescent beads

Raw image composites are in the format PlateName-Well_A01-Pos1,  
where A01 indicates the well coordinates in the plate and Pos1 the field 1 acquired in the well
For this dataset, 11 positions were acquired in each well

Works after Macro 1
*/


////////////////////////// Image J parameter /////////////////////////////////////////////////

run("Set Measurements...", "area mean standard min centroid center integrated median display redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black");

//////////////////////////////////////////////////////////////////////////////////////////////



///////////////////////////// Folder Management /////////////////////////////////////////////

/*
If mydatasPathway/FolderName is your data's folder, Part1 creates :
mydatasPathway/FolderName_Extracted_Couple/Individual_Rois
mydatasPathway/FolderName_Extracted_Couple/Extraction_Masks
Part2 add :
mydatasPathway/FolderName_Extracted_Couple/Analysis
*/

dirdata = getDirectory("Plate composite directory");
dirExtracted = substring(dirdata,0, lengthOf(dirdata)-1)+"_Extracted_Couple"+File.separator();
dir1=dirExtracted+"Individual_Rois_and_Masks"+File.separator;
dir2=dirExtracted+"Extraction_Masks"+File.separator;

dirAnalysis=dirExtracted+"Analysis"+File.separator;
File.makeDirectory(dirAnalysis);

list=getFileList(dirExtracted);

///////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////// Extraction parameters ////////////////////////////////

/*
Enter the coordinates of the wells and positions to process (must have a single space in between each letter or number)
*/

Dialog.create("Couple bead cell extraction parameters");
Dialog.addString("Plate Name", "Rep1-Plate1", 25);
Dialog.addString("well letter to process", "B C D E F G", 25);
Dialog.addString("well line to process", "01 02 03 04 05 06 07 08 09 10 11", 25);
Dialog.addNumber("mToc channel index",1, 0 , 8, "");
Dialog.addNumber("Lysosomes channel index",3, 0 , 8, "");
Dialog.addString("mToc thresholding method", "Yen", 20);
Dialog.show(); 
PlateName =Dialog.getString();
LetterText=Dialog.getString();
LinesText=Dialog.getString();
mtocChan = Dialog.getNumber();
lysosChan = Dialog.getNumber();
Threshmtoc = Dialog.getString();


LetterArray=split(LetterText, " \t\n\r"); // split the text from the dialog box
LineArray=split(LinesText, " \t\n\r");


////////////////////////////////////////////////////////////

if(isOpen("Log")) {
	selectWindow("Log");
	run("Close");
}

///////////// Analysis of cell-bead pairs ////////////////

setBatchMode(true);

for (i=0 ; i<LetterArray.length ; i++) {
	Letter=LetterArray[i];
	for (j=0 ; j<LineArray.length ; j++) {
		Line=LineArray[j];
		print("Well"+Letter+Line);
		nbExtracted=0;
		for(k=0;k<lengthOf(list);k++) {
			if(startsWith(list[k], PlateName+"-Well_"+Letter+Line+"-Pos")) {
				nbExtracted=nbExtracted+1;
			}
		}
		
		MtocPolarity=newArray(nbExtracted);
		LysosPolarity=newArray(nbExtracted);
		
		nbExtracted=0;
		for(k=0;k<lengthOf(list);k++) {
			if(startsWith(list[k], PlateName+"-Well_"+Letter+Line+"-Pos")) {
				run("Clear Results");
				roiManager("reset");
				open(dirExtracted+list[k]);
				cellName=substring(list[k],0,lengthOf(list[k])-4);
				
				open(dir1+cellName+"_beadMask.tif");
				run("Measure");
				open(dir1+cellName+"_cellMask.tif");
				run("Measure");
				
				Xbead=getResult("XM",0);
				Ybead=getResult("YM",0);
				Xcell=getResult("XM",1);
				Ycell=getResult("YM",1);
				
				
				////////////// Centrosome polarity /////////////
				selectWindow(list[k]);
				run("Duplicate...", "title=tempmToc duplicate channels="+mtocChan+"");
				run("Clear Outside", "stack");
				run("8-bit");
				run("Auto Threshold", "method="+Threshmtoc+" white");
				run("Analyze Particles...", "size=5-50 pixel circularity=0.00-1.00 show=Masks");	/// remove big patches
				selectWindow("Mask of tempmToc");
				run("Select All");
				run("Measure");
				Xmtoc=getResult("XM",2);
				Ymtoc=getResult("YM",2);

				distanceBeadCell=sqrt((Xcell-Xbead)*(Xcell-Xbead)+(Ycell-Ybead)*(Ycell-Ybead));
				distanceCellMtoc=sqrt((Xcell-Xmtoc)*(Xcell-Xmtoc)+(Ycell-Ymtoc)*(Ycell-Ymtoc));
				
				makeSelection("angle",newArray(Xmtoc,Xcell,Xbead),newArray(Ymtoc,Ycell,Ybead));
				roiManager("add");
				run("Measure");
				angle=getResult("Angle",3);
				angleRad=angle*2*PI/360;
				distprojmtoc=distanceCellMtoc*cos(angleRad);
				if(getResult("RawIntDen",2)>(4*255) && getResult("RawIntDen",2)<(100*255)) { /// if more than 5px and less than 100px, centrosome is detected 
				MtocPolarity[nbExtracted]=distprojmtoc/distanceBeadCell;
				roiManager("Save" , dirAnalysis+cellName+"_ControlMtoc_Polarity.zip");
				} else {
				MtocPolarity[nbExtracted]=NaN;
				}
				
				//////////////////////////////////////////
				
				///////////// Lysosome polarity ////////////
				selectWindow(list[k]);
				makeLine(Xcell, Ycell, Xbead, Ybead, 1);
				run("Measure");
				anglebead=round(getResult("Angle",4));

				selectWindow(list[k]);
				run("Select None");
				run("Rotate... ", "angle="+anglebead+" grid=1 interpolation=Bilinear stack enlarge");
				saveAs("Tiff", dirAnalysis+cellName+"_rotated.tif");
				
				selectWindow(cellName+"_cellMask.tif");
				run("Rotate... ", "angle="+anglebead+" grid=1 interpolation=Bilinear enlarge");
				run("Make Binary");
				run("Create Selection");

				selectWindow(cellName+"_rotated.tif");
				run("Restore Selection");
				run("Duplicate...", "title=Lysos duplicate channels="+lysosChan+"");
				run("Clear Outside", "stack");
				run("Measure");
				lysobg=getResult("Median", 5);

				selectWindow("Lysos");
				Stack.getDimensions(width, height, channels, slices, frames);
				run("Select None");
				run("Subtract...", "value="+lysobg+"");
				run("Select All");
				run("Measure");
				lysototInt=getResult("RawIntDen", 6);
				makeRectangle(2*width/3,0,width/3,height);
				run("Measure");
				lysosynapsInt=getResult("RawIntDen", 7);

				LysosPolarity[nbExtracted]=lysosynapsInt/lysototInt;
				
				selectWindow("Lysos");
				saveAs("Tiff", dirAnalysis+cellName+"_LysosCtrl.tif");
				
				/////////////////////////////////////////
				
				nbExtracted=nbExtracted+1;
				run("Close All");
			}
		}
		
		if(isOpen("Results")) {
			selectWindow("Results");
			run("Close");
		}
		
		nbExtracted=0;
		for(k=0;k<lengthOf(list);k++) {
			if(startsWith(list[k], PlateName+"-Well_"+Letter+Line+"-Pos")) {
				setResult("Cell Name", nbExtracted, list[k]);
				setResult("Mtoc polarity", nbExtracted, MtocPolarity[nbExtracted]);
				setResult("Lysos polarity", nbExtracted, LysosPolarity[nbExtracted]);
				nbExtracted=nbExtracted+1;
			}
		}
		
	
	if(nbExtracted>0) {
		updateResults();
		selectWindow("Results");
		saveAs("Results",dirAnalysis+PlateName+"-Well_"+Letter+Line+"_Results.txt");
		run("Close");
	}
		
	}	/// Line
} /// Letter

setBatchMode(false);


