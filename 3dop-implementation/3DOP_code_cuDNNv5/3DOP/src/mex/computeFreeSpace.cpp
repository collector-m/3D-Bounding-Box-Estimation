
#include <iostream>
#include <cstring>
#include <stdio.h>
#include <cmath>
#include "mex.h"

struct voxelData {
	double *voxelID;
	double *minVoxelCoord;
	double *maxVoxelCoord;
	double *numDivisions;
	double *divMultiplier;
	double ***leafLayout;
};



void mexFunction( int nlhs, mxArray *plhs[],
		int nrhs, const mxArray *prhs[])
{
	const char **fnames;       /* pointers to field names */
	int nfields, ifield;
	mwSize NStructElems;
	mwSize ndim;
	const mwSize *dims;
	mxArray *fout;
	mxArray *tmp;
	mxClassID  *classIDflags;
	mwIndex jstruct;
	double *pdata=NULL;

	// expected struct fields
	int numFields = 6;
	char *fieldNames[] = {"voxelID", "minVoxelCoord", "maxVoxelCoord", "numDivisions", "divMultiplier", "leafLayout"};
	int fieldNameMapping[numFields];

	nfields = mxGetNumberOfFields(prhs[0]);
	ifield = mxGetNumberOfElements(prhs[0]);
	NStructElems = mxGetNumberOfElements(prhs[0]);

	fnames = (const char **)mxCalloc(nfields, sizeof(*fnames));
	classIDflags = (mxClassID *)mxCalloc(nfields, sizeof(mxClassID));
	mxArray *voxelParams[1];
	jstruct = 0;
	/* get field name pointers */
	for (ifield=0; ifield< nfields; ifield++){
		fnames[ifield] = mxGetFieldNameByNumber(prhs[0],ifield);
		for(int i = 0; i < numFields; ++i) {
			if(strcmp(fnames[ifield], fieldNames[i]) == 0) {
				fieldNameMapping[i] = ifield;
			}
		}
		tmp = mxGetFieldByNumber(prhs[0], jstruct, ifield);
		classIDflags[ifield] = mxGetClassID(tmp);
	}

	// Computing Free Space
	tmp = mxGetField(prhs[0], 0, "leafLayout");
	const int *gridSizes = mxGetDimensions(tmp);
	double *pointSpace;
	plhs[0] = mxDuplicateArray(prhs[1]);

	pointSpace = (double *)mxGetData(prhs[1]);

	double *freeSpace;
	freeSpace = (double *)mxGetData(plhs[0]);
	std::fill(freeSpace, freeSpace + mxGetNumberOfElements(prhs[1]), 1);

	int xs, ys, zs;

	double *minVoxelCoord, *maxVoxelCoord, *temp_divMultiplier;
	int divMultiplier[3];
	tmp = mxGetField(prhs[0], 0, "minVoxelCoord");
	minVoxelCoord = (double *)mxGetData(tmp);
	tmp = mxGetField(prhs[0], 0, "maxVoxelCoord");
	maxVoxelCoord = (double *)mxGetData(tmp);
	tmp = mxGetField(prhs[0], 0, "divMultiplier");
	temp_divMultiplier = (double *)mxGetData(tmp);
	for(int i = 0; i < mxGetNumberOfElements(tmp); ++i) {
		divMultiplier[i] = (int)temp_divMultiplier[i];
	}

	for(int i = 0; i < gridSizes[0]; ++i) {
		xs = i + minVoxelCoord[0];
		for(int j = 0; j < gridSizes[1]; ++j) {
			ys = j + minVoxelCoord[1];
			for (int k = 0; k < gridSizes[2]; ++k) {
				if(pointSpace[i + j*divMultiplier[1] + k*divMultiplier[2]] > 0) {
					freeSpace[i + j*divMultiplier[1] + k*divMultiplier[2]] = 0;
				} else {
					continue;
				}
				zs = k + minVoxelCoord[2];
				for(int sz = zs + 1; sz <= maxVoxelCoord[2]; ++sz) {
					double deltaInc = (1.0 * sz)/zs;
					int sx = round(deltaInc*xs);
					if(sx < minVoxelCoord[0] || sx > maxVoxelCoord[0]) {
						continue;
					}
					int sy = round(deltaInc*ys);
					if(sy < minVoxelCoord[1] || sy > maxVoxelCoord[1]) {
						continue;
					}
					int temp_x = sx - minVoxelCoord[0];
					int temp_y = sy - minVoxelCoord[1];
					int temp_z = sz - minVoxelCoord[2];
					if(temp_x < 0 || temp_x >= gridSizes[0]) {
						std::cout << "CrashX ";
						std::cout << "(" << temp_x << ", " << temp_y << ", " << temp_z << ")";
						std::cout << "(" << i << ", " << j << ", " << k << ")\n";
						fflush(stdout);
					}
					if(temp_y < 0 || temp_y >= gridSizes[1]) {
						std::cout << "CrashY ";
						std::cout << "(" << temp_x << ", " << temp_y << ", " << temp_z << ")";
						std::cout << "(" << i << ", " << j << ", " << k << ")\n";
						fflush(stdout);
					}
					if(temp_z < 0 || temp_z >= gridSizes[2]) {
						std::cout << "CrashZ ";
						std::cout << "(" << temp_x << ", " << temp_y << ", " << temp_z << ")";
						std::cout << "(" << i << ", " << j << ", " << k << ")\n";
						fflush(stdout);
					}
					freeSpace[temp_x + temp_y*divMultiplier[1] + temp_z*divMultiplier[2]] = 0;
				}
			}
		}
	}
	return;
}
