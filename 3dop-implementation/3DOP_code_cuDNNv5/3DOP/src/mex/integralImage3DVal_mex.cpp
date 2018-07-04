#include "mex.h"
//#include <iostream>
//using namespace std;

// with boxes stored in row-major: 6xN
void integralImage3DVal_RowMajor(int* boxes, const int N, float* img,
        const int W, const int H, float* vals)
{
    int WH = W * H;
    
    int x1, y1, z1, x2, y2, z2, dx, dy, dz;
    int* box;
    float *im1, *im2;
    for (int i = 0; i < N; ++i)
    {
        box = boxes + i*6;
        x1 = *box - 1;
        y1 = *(box + 1) - 1;
        z1 = *(box + 2) - 1;
        x2 = *(box + 3);
        y2 = *(box + 4);
        z2 = *(box + 5);
        
        im1 = img + x1 + y1*W + z1*WH;
        im2 = img + x2 + y2*W + z2*WH;
        dx = x2 - x1;
        dy = (y2 - y1) * W;
        dz = (z2 - z1) * WH;
        
        vals[i] = *im2 + *(im1 + dz) 
                + *(im1 + dy) + *(im1 + dx)
                - *(im2 - dy) - *(im2 - dx)
                - *(im2 - dz) - *im1;
    }
}
    
// boxes: Nx6
void integralImage3DVal(int* boxes, const int N, const float* img,
        const int W, const int H, float* vals)
{
    int WH = W * H;
    #define I(i,j,k) img[i + j*W + k*WH]
    #define B(i,j) boxes[i + j*N]
    
    int x1, y1, z1, x2, y2, z2;
    for (int i = 0; i < N; ++i)
    {
        x1 = B(i,0) - 1;
        y1 = B(i,1) - 1;
        z1 = B(i,2) - 1;
        x2 = B(i,3);
        y2 = B(i,4);
        z2 = B(i,5);
        vals[i] = I(x2,y2,z2) + I(x1,y1,z2) + I(x1,y2,z1) + I(x2,y1,z1)
                - I(x1,y2,z2) - I(x2,y1,z2) - I(x2,y2,z1) - I(x1,y1,z1);        
    }
}

void mexFunction( int nl, mxArray *pl[], int nr, const mxArray *pr[] )
{
    if (nr != 3 || nl != 1)
    {
        mexErrMsgTxt("Check the input.\nUsage: out = 3DIntegralImageVal_mex(boxes, image3D, sizes)\n");
    }
    
    // boxes is a 6xN matrix
    int P = (int)mxGetM(pr[0]);
    int N = (int)mxGetN(pr[0]);
    if (P  != 6)
        mexErrMsgTxt("size of the first parameter boxes should be N*6!\n");
    int* boxes = (int *)mxGetData(pr[0]);
    
    // image
    float *I = (float*) mxGetData(pr[1]);
    
    double* dims = (double *)mxGetData(pr[2]);
    int D1 = (int) dims[0];
    int D2 = (int) dims[1];
        
    // Output
    pl[0] = mxCreateNumericMatrix(N, 1, mxSINGLE_CLASS, mxREAL);
    float *vals = (float*) mxGetData(pl[0]);
    
   // IntegralImage3DVal(boxes, N, I, D1, D2, vals);
    integralImage3DVal_RowMajor(boxes, N, I, D1, D2, vals);
}