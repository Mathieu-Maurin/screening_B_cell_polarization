//////////////////////////////////////////////////////////////////
////// Macro 3: Normalization and Concatenation of tables ///////
////////////////////////////////////////////////////////////////

/*
The purpose of this macro is to normalize data and concatenate tables

Results are in the format PlateName-Well_A01_Results,
where A01 indicates the well coordinate in the plate 
It contains all the results from centrosome and lysosome polarity indexes from all positions of a given well

It concatenates and normalizes data to get a single table for Centrosome and lysosome polarity indexes
It also computes median values for each well

Normalization is based on the median value of B01 (that is thus normalized to 1)

Works after Macro 2
*/




///////////////////////////// Folder Management /////////////////////////////////////////////


dirdata = getDirectory("Plate composite directory");
dirExtracted = substring(dirdata,0, lengthOf(dirdata)-1)+"_Extracted_Couple"+File.separator();

dirAnalysis=dirExtracted+"Analysis"+File.separator;
dirTables=dirExtracted+"Final_Tables"+File.separator;

File.makeDirectory(dirTables);


list=getFileList(dirAnalysis);

///////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////  Extraction parameters ///////////////////////////////


Dialog.create("Data_Normalisation_Parameters");
Dialog.addString("Plate_Name", "Rep1-Plate1", 25);
Dialog.addString("well letter to process", "B C D E F G", 25);
Dialog.addString("well line to process", "01 02 03 04 05 06 07 08 09 10 11", 25);
Dialog.addString("Reference well for normalisation", "B01", 25);
Dialog.show(); 
PlateName =Dialog.getString();
LetterText=Dialog.getString();
LinesText=Dialog.getString();
RefWell=Dialog.getString();


LetterArray=split(LetterText, " \t\n\r"); // split the text from the dialog box
LineArray=split(LinesText, " \t\n\r");


////////////////////////////////////////////////////////////


if(isOpen("Results")) {
	selectWindow("Results");
	run("Close");
}

///////////// Concatenate and normalize tables ////////////////

run("Results... ", "open=["+dirAnalysis+PlateName+"-Well_"+RefWell+"_Results.txt]");
nbCell=nResults();
PolarityMtoc=newArray(nbCell);
PolarityLysos=newArray(nbCell);
for(cell=0;cell<nbCell;cell++) {
	PolarityMtoc[cell]=getResult("Mtoc polarity", cell);
	PolarityLysos[cell]=getResult("Lysos polarity", cell);
}

selectWindow("Results");
run("Close");

/// median values

PolarityMtocNaN=Array.deleteValue(PolarityMtoc, NaN);

Array.sort(PolarityMtocNaN);

Array.sort(PolarityLysos);


if(lengthOf(PolarityMtocNaN)>0) {
	if(((lengthOf(PolarityMtocNaN)/2)-floor(lengthOf(PolarityMtocNaN)/2))!=0) {
		medianMtocRef=PolarityMtocNaN[lengthOf(PolarityMtocNaN)/2];
	} else {
		medianMtocRef=(PolarityMtocNaN[floor(lengthOf(PolarityMtocNaN)/2)]+PolarityMtocNaN[floor(lengthOf(PolarityMtocNaN)/2)-1])/2;
	}
} 


if(lengthOf(PolarityLysos)>0) {
	if(((lengthOf(PolarityLysos)/2)-floor(lengthOf(PolarityLysos)/2))!=0) {
		medianLysosRef=PolarityLysos[lengthOf(PolarityLysos)/2];
	} else {
		medianLysosRef=(PolarityLysos[floor(lengthOf(PolarityLysos)/2)]+PolarityLysos[floor(lengthOf(PolarityLysos)/2)-1])/2;
	}
} 



if(isOpen("Log")) {
	selectWindow("Log");
	run("Close");
}

WellName=newArray(1);
WellName[0]=PlateName+"-Well";
mtocValue=newArray(1);
mtocValue[0]="Median_mtoc_polarity";
mtocNormalisedValue=newArray(1);
mtocNormalisedValue[0]="Median_mtoc_polarity_normalised";
lysosValue=newArray(1);
lysosValue[0]="Median_lysos_polarity";
lysosNormalisedValue=newArray(1);
lysosNormalisedValue[0]="Median_lysos_polarity_normalised";

for (i=0 ; i<LetterArray.length ; i++) {
	Letter=LetterArray[i];
	for (j=0 ; j<LineArray.length ; j++) {
		Line=LineArray[j];
		for(k=0;k<lengthOf(list);k++) {
			if(startsWith(list[k], PlateName+"-Well_"+Letter+Line+"_Results.txt")) {
				run("Results... ", "open=["+dirAnalysis+list[k]+"]");
				nbCell=nResults();
				PolarityMtoc=newArray(nbCell);
				for(cell=0;cell<nbCell;cell++) {
					PolarityMtoc[cell]=getResult("Mtoc polarity", cell);
				}
				
				selectWindow("Results");
				run("Close");
								
				ArrayTitle=newArray(1);
				ArrayTitle[0]=Letter+Line;
				Arraymtoc=Array.concat(ArrayTitle,PolarityMtoc);
				Array.print(Arraymtoc);
				
				/// median
				PolarityMtocNaN=Array.deleteValue(PolarityMtoc, NaN);
				
				Array.sort(PolarityMtocNaN);

				medianMtoc=newArray(1);
				if(lengthOf(PolarityMtocNaN)>0) {
					if(((lengthOf(PolarityMtocNaN)/2)-floor(lengthOf(PolarityMtocNaN)/2))!=0) {
						medianMtoc[0]=PolarityMtocNaN[lengthOf(PolarityMtocNaN)/2];
					} else {
						medianMtoc[0]=(PolarityMtocNaN[floor(lengthOf(PolarityMtocNaN)/2)]+PolarityMtocNaN[floor(lengthOf(PolarityMtocNaN)/2)-1])/2;
					}
				} else {
				medianMtoc[0]=NaN;
				}
				
				WellName=Array.concat(WellName,ArrayTitle);
				mtocValue=Array.concat(mtocValue,medianMtoc);

			}
		}
								
	}	/// Line
} /// Letter

selectWindow("Log");
saveAs("Text",dirTables+PlateName+"_ResultsMtoc.txt");
run("Close");

for (i=0 ; i<LetterArray.length ; i++) {
	Letter=LetterArray[i];
	for (j=0 ; j<LineArray.length ; j++) {
		Line=LineArray[j];
		for(k=0;k<lengthOf(list);k++) {
			if(startsWith(list[k], PlateName+"-Well_"+Letter+Line+"_Results.txt")) {
				run("Results... ", "open="+dirAnalysis+list[k]);
				nbCell=nResults();
				PolarityMtoc=newArray(nbCell);
				for(cell=0;cell<nbCell;cell++) {
					PolarityMtoc[cell]=getResult("Mtoc polarity", cell)/medianMtocRef;
				}
				
				selectWindow("Results");
				run("Close");
								
				ArrayTitle=newArray(1);
				ArrayTitle[0]=Letter+Line;
				Arraymtoc=Array.concat(ArrayTitle[0],PolarityMtoc);
				Array.print(Arraymtoc);
				
				/// median
				PolarityMtocNaN=Array.deleteValue(PolarityMtoc, NaN);
				
				Array.sort(PolarityMtocNaN);
				
				medianMtoc=newArray(1);
				if(lengthOf(PolarityMtocNaN)>0) {
					if(((lengthOf(PolarityMtocNaN)/2)-floor(lengthOf(PolarityMtocNaN)/2))!=0) {
						medianMtoc[0]=PolarityMtocNaN[lengthOf(PolarityMtocNaN)/2];
					} else {
						medianMtoc[0]=(PolarityMtocNaN[floor(lengthOf(PolarityMtocNaN)/2)]+PolarityMtocNaN[floor(lengthOf(PolarityMtocNaN)/2)-1])/2;
					}
				} else {
				medianMtoc[0]=NaN;
				}
				
				mtocNormalisedValue=Array.concat(mtocNormalisedValue,medianMtoc);
				

			}
		}
								
	}	/// Line
} /// Letter

selectWindow("Log");
saveAs("Text",dirTables+PlateName+"_ResultsMtoc_Normalised.txt");
run("Close");


for (i=0 ; i<LetterArray.length ; i++) {
	Letter=LetterArray[i];
	for (j=0 ; j<LineArray.length ; j++) {
		Line=LineArray[j];
		for(k=0;k<lengthOf(list);k++) {
			if(startsWith(list[k], PlateName+"-Well_"+Letter+Line+"_Results.txt")) {
				run("Results... ", "open="+dirAnalysis+list[k]);
				nbCell=nResults();
				PolarityLysos=newArray(nbCell);
				for(cell=0;cell<nbCell;cell++) {
					PolarityLysos[cell]=getResult("Lysos polarity", cell);
				}
				
				selectWindow("Results");
				run("Close");
								
				ArrayTitle=newArray(1);
				ArrayTitle[0]=Letter+Line;
				ArrayLysos=Array.concat(ArrayTitle[0],PolarityLysos);
				Array.print(ArrayLysos);
				
				/// median

				Array.sort(PolarityLysos);


				medianLysos=newArray(1);
				if(lengthOf(PolarityLysos)>0) {
					if(((lengthOf(PolarityLysos)/2)-floor(lengthOf(PolarityLysos)/2))!=0) {
						medianLysos[0]=PolarityLysos[lengthOf(PolarityLysos)/2];
					} else {
						medianLysos[0]=(PolarityLysos[floor(lengthOf(PolarityLysos)/2)]+PolarityLysos[floor(lengthOf(PolarityLysos)/2)-1])/2;
					}
				} 
				
				lysosValue=Array.concat(lysosValue,medianLysos);

			}
		}								
	}	/// Line
} /// Letter

selectWindow("Log");
saveAs("Text",dirTables+PlateName+"_ResultsLysos.txt");
run("Close");


for (i=0 ; i<LetterArray.length ; i++) {
	Letter=LetterArray[i];
	for (j=0 ; j<LineArray.length ; j++) {
		Line=LineArray[j];
		for(k=0;k<lengthOf(list);k++) {
			if(startsWith(list[k], PlateName+"-Well_"+Letter+Line+"_Results.txt")) {
				run("Results... ", "open="+dirAnalysis+list[k]);
				nbCell=nResults();
				PolarityLysos=newArray(nbCell);
				for(cell=0;cell<nbCell;cell++) {
					PolarityLysos[cell]=getResult("Lysos polarity", cell)/medianLysosRef;
				}
				
				selectWindow("Results");
				run("Close");
								
				ArrayTitle=newArray(1);
				ArrayTitle[0]=Letter+Line;
				ArrayLysos=Array.concat(ArrayTitle[0],PolarityLysos);
				Array.print(ArrayLysos);
				
				/// median

				Array.sort(PolarityLysos);


				medianLysos=newArray(1);
				if(lengthOf(PolarityLysos)>0) {
					if(((lengthOf(PolarityLysos)/2)-floor(lengthOf(PolarityLysos)/2))!=0) {
						medianLysos[0]=PolarityLysos[lengthOf(PolarityLysos)/2];
					} else {
						medianLysos[0]=(PolarityLysos[floor(lengthOf(PolarityLysos)/2)]+PolarityLysos[floor(lengthOf(PolarityLysos)/2)-1])/2;
					}
				} 
				
				lysosNormalisedValue=Array.concat(lysosNormalisedValue,medianLysos);

			}
		}								
	}	/// Line
} /// Letter

selectWindow("Log");
saveAs("Text",dirTables+PlateName+"_ResultsLysos_Normalised.txt");
run("Close");


///// Generate tables containing median values
if(isOpen("Results")) {
	selectWindow("Results");
	run("Close");
}


for(i=1;i<lengthOf(WellName);i++) {
	setResult(""+PlateName+"-Well",i-1,WellName[i]);
	setResult("Median_mtoc_polarity",i-1,mtocValue[i]);
	setResult("Median_mtoc_polarity_normalised",i-1,mtocNormalisedValue[i]);
	setResult("Median_lysos_polarity",i-1,lysosValue[i]);
	setResult("Median_lysos_polarity_normalised",i-1,lysosNormalisedValue[i]);
}
updateResults();
selectWindow("Results");
saveAs("Results",dirTables+PlateName+"_FinalTable.txt");
run("Close");
