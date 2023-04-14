////////////////////////////////////////////////////////////////
////// Macro 4: Control beads cells and couple count ///////////
////////////////////////////////////////////////////////////////

/*
The purpose of this macro is to control beads cells and couple count

Results are in the format PlateName-Well_A01_Results,
where A01 indicates the well coordinate in the plate 
It contains all the results from centrosome and lysosome polarity indexes from all positions of a given well

Works after Macro 3
*/




///////////////////////////// Folder Management /////////////////////////////////////////////


dirdata = getDirectory("Plate composite directory");
dirExtracted = substring(dirdata,0, lengthOf(dirdata)-1)+"_Extracted_Couple"+File.separator();

dirAnalysis=dirExtracted+"Analysis"+File.separator;
dirTables=dirExtracted+"Final_Tables"+File.separator;
dirCtrl=dirExtracted+"Extraction_Masks"+File.separator;

//File.makeDirectory(dirTables);


list=getFileList(dirAnalysis);

///////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////  Extraction parameters ///////////////////////////////


Dialog.create("Data_Normalisation_Parameters");
Dialog.addString("Plate_Name", "Rep1-Plate1", 25);
Dialog.addString("well letter to process", "B C D E F G", 25);
Dialog.addString("well line to process", "01 02 03 04 05 06 07 08 09 10 11", 25);
Dialog.addString("field to process", "1 2 3 4 5 6 7 8 9 10 11", 25);
Dialog.show(); 
PlateName =Dialog.getString();
LetterText=Dialog.getString();
LinesText=Dialog.getString();
FieldText=Dialog.getString();


LetterArray=split(LetterText, " \t\n\r"); // split the text from the dialog box
LineArray=split(LinesText, " \t\n\r");
FieldArray=split(FieldText, " \t\n\r");

////////////////////////////////////////////////////////////


if(isOpen("Results")) {
	selectWindow("Results");
	run("Close");
}


if(isOpen("Log")) {
	selectWindow("Log");
	run("Close");
}

WellName=newArray(1);
WellName[0]=PlateName+"-Well";
CellNum=newArray(1);
CellNum[0]="NbCells";
BeadNum=newArray(1);
BeadNum[0]="NbBeads";
CoupleNum=newArray(1);
CoupleNum[0]="NbCouples";


for (i=0 ; i<LetterArray.length ; i++) {
	Letter=LetterArray[i];
	for (j=0 ; j<LineArray.length ; j++) {
		Line=LineArray[j];
		for(k=0;k<lengthOf(list);k++) {
			if(startsWith(list[k], PlateName+"-Well_"+Letter+Line+"_Results.txt")) {
				run("Results... ", "open=["+dirAnalysis+list[k]+"]");
				nbCouple=newArray(1);
				nbCouple[0]=nResults();
				well=newArray(1);
				well[0]=Letter+Line;
				
				CellCount=0;
				BeadCount=0;
				
				for(l=0;l<FieldArray.length;l++) {
					Field=FieldArray[l];
					if(File.exists(dirCtrl+PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_RoiSetCells.zip")) {
						roiManager("reset");
						roiManager("open",dirCtrl+PlateName+"-Well_"+Letter+Line+"-Pos"+Field+"_RoiSetCells.zip");
						CellCount=CellCount+roiManager("count");
					}
					if(File.exists(dirCtrl+Letter+Line+"_s"+Field+"RoiSetBeads.zip")) {
						roiManager("reset");
						roiManager("open",dirCtrl+Letter+Line+"_s"+Field+"RoiSetBeads.zip");
						BeadCount=BeadCount+roiManager("count");
					}
					
				}
				
				nbCell=newArray(1);
				nbCell[0]=CellCount;
				nbBead=newArray(1);
				nbBead[0]=BeadCount;	

				
				selectWindow("Results");
				run("Close");
				
				roiManager("reset");
				
				WellName=Array.concat(WellName,well);
				CoupleNum=Array.concat(CoupleNum,nbCouple);
				CellNum=Array.concat(CellNum,nbCell);
				BeadNum=Array.concat(BeadNum,nbBead);
			}
		}
								
	}	/// Line
} /// Letter



///// Generate tables 
if(isOpen("Results")) {
	selectWindow("Results");
	run("Close");
}


for(i=1;i<lengthOf(WellName);i++) {
	setResult(""+PlateName+"-Well",i-1,WellName[i]);
	setResult("Number_of_cells",i-1,CellNum[i]);
	setResult("Number_of_beads",i-1,BeadNum[i]);
	setResult("Number_of_couples",i-1,CoupleNum[i]);
}
updateResults();
selectWindow("Results");
saveAs("Results",dirTables+PlateName+"_Cell_Beads_Count.txt");
run("Close");
