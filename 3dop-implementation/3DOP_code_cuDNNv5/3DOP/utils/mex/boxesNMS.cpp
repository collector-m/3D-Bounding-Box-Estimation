// Non-maximal Suppression
        
#include "mex.h"
#include <vector>
#include <algorithm>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
//#include <windows.h>
#include <cmath>
using namespace std;

int clamp( int v, int a, int b ) { return v<a?a:v>b?b:v; }
#define fast_max(x,y) (x - ((x - y) & ((x - y) >> (sizeof(int) * CHAR_BIT - 1))))
#define fast_min(x,y) (y + ((x - y) & ((x - y) >> (sizeof(int) * CHAR_BIT - 1))))

// bounding box data structures and routines
typedef struct { int x1, y1, x2, y2, id; float s; } Box;
typedef vector<Box> Boxes;
bool boxesComp( const Box &a, const Box &b ) { return a.s < b.s; }

float boxesOverlap( Box &a, Box &b ) {
  float areai, areaj, areaij;
  int r0, r1, c0, c1, dx, dy;
  areai = (float) (a.x2 - a.x1) * (a.y2 - a.y1); r0=max(a.x1, b.x1); r1=min(a.x2,b.x2);
  areaj = (float) (b.x2 - b.x1) * (b.y2 - b.y1); c0=max(a.y1, b.y1); c1=min(a.y2,b.y2);
  areaij = (float) max(0,r1-r0) * max(0, c1-c0);
  return areaij / (areai + areaj - areaij);
}

void boxesNms( Boxes &boxes, float thr, int maxBoxes )
{
  sort(boxes.rbegin(),boxes.rend(),boxesComp);
  if( thr>.99 ) return; const int nBin=10000;
  const float step=1/thr, lstep=log(step);
  vector<Boxes> kept; kept.resize(nBin+1);
  int i=0, j, k, n=(int) boxes.size(), m=0, b;
  while( i<n && m<maxBoxes )
  {
    b = (boxes[i].x2 - boxes[i].x1 + 1) * (boxes[i].y2 - boxes[i].y1 + 1);
    bool keep=1;
    b = clamp(int(ceil(log(float(b))/lstep)),1,nBin-1);
    for( j=b-1; j<=b+1; j++ )
      for( k=0; k<kept[j].size(); k++ )
          if( keep )
            keep = boxesOverlap( boxes[i], kept[j][k] ) <= thr;
    if(keep) 
    { 
        kept[b].push_back(boxes[i]); 
        m++; 
    }
    i++;
  }
  boxes.resize(m); i=0;
  for( j=0; j<nBin; j++ )
    for( k=0; k<kept[j].size(); k++ )
      boxes[i++]=kept[j][k];
  sort(boxes.rbegin(),boxes.rend(),boxesComp);
}

// Fit segments
void nms(const int* inBBs, const float* scores, const int num, const float beta, const int maxBoxes, Boxes& outBBs)
{
#define I(row,col) inBBs[(col) * num + row]

    outBBs.resize(0);
    for (int i = 0; i < num; i++)
    {
        Box b;
        b.x1 = I(i,0); b.y1 = I(i,1);
        b.x2 = I(i,2); b.y2 = I(i,3);
        b.s = scores[i];
        b.id = i;
        outBBs.push_back(b);                
    }      
    
    boxesNms(outBBs, beta, maxBoxes);
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if ((nrhs != 3 && nrhs != 4) || (nlhs != 1 & nlhs !=2))
    {
        mexErrMsgTxt("Check the input.\nUsage: [out, IDX] = boxesNMS(boxes, scores, threshold [,N])\n");
    }
    
    int num = (int)mxGetM(prhs[0]);
    int colNum0 = (int)mxGetN(prhs[0]);
    if (colNum0  != 4)
        mexErrMsgTxt("size of the first parameter boxes should be N*4!\n");
    int* inBBs = (int *)mxGetData(prhs[0]);
    
    int num2 = (int)mxGetM(prhs[1]);
    colNum0 = (int)mxGetN(prhs[1]);
    if (colNum0  != 1 || num != num2)
        mexErrMsgTxt("size of the second parameter scores should be N*1!\n");
    float* scores = (float *)mxGetData(prhs[1]);
    
    float thr = float(mxGetScalar(prhs[2]));
    
    int maxBoxes = 10000;
    if (nrhs > 3)
        maxBoxes = int(mxGetScalar(prhs[3]));
        
    Boxes outBBs;    
    nms(inBBs, scores, num, thr, maxBoxes, outBBs);
    
    // Output
    int numI = outBBs.size();
    plhs[0] = mxCreateNumericMatrix(numI, 5, mxSINGLE_CLASS, mxREAL);
    float *bbs = (float*) mxGetData(plhs[0]);
    plhs[1] = mxCreateNumericMatrix(numI, 1, mxSINGLE_CLASS, mxREAL);
    float *ids = (float*) mxGetData(plhs[1]);
    for(int i = 0; i < numI; i++)    
    {
        bbs[ i ] = (float) outBBs[i].x1;
        bbs[ i + 1*numI ] = (float) outBBs[i].y1;
        bbs[ i + 2*numI ] = (float) outBBs[i].x2;
        bbs[ i + 3*numI ] = (float) outBBs[i].y2;
        bbs[ i + 4*numI ] = (float) outBBs[i].s;
        ids[i] = (float) outBBs[i].id + 1;
    }
}