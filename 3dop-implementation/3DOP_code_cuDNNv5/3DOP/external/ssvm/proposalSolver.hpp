/*  This file is part of 3D Object Proposals (3DOP): http://www.cs.toronto.edu/~objprop3d/
 *  3DOP is copyright by Xiaozhi Chen, Kaustav Kunku, Yukun Zhu, Andrew Berneshawi,
 *  Huimin Ma, Sanja Fidler and Raquel Urtasun. It is released for personal or
 *  academic use only. Any commercial use is strictly prohibited except by explicit
 *  permission by the authors. For more information on commercial use, contact
 *  Raquel Urtasun.
 *
 *  The authors of this software and corresponding paper assume no liability for
 *  its use and by using this software you agree to these terms.
 */

#include <iostream>
#include "util.hpp"


const static int _N = 5; // number of features
const static bool PRELOAD = true; // set true if pre-load all the features (~30G memory required)
typedef Eigen::Matrix<float, Eigen::Dynamic, _N> MatrixXNf;

class proposalSolver
{
  public:
    proposalSolver() {};
    ~proposalSolver() {};
    vectori load(std::string fn);
    int featureVector(const vectori& y, vectord& phi);
    vectori infer(const vectord& weights);
    double loss(const vectori& labeling);

  protected:
    std::string featFile;
    vectori gtID;
    Eigen::VectorXf allLoss;
    MatrixXNf features;
};


// implementation
vectori proposalSolver::load(std::string fn)
{
  unsigned found = fn.find_last_of(".");
  featFile = fn.substr(0, found) + ".feat";
  //std::cout << featFile << std::endl;

  // load ground truth label
  if (readFile(fn.c_str(), &gtID) == -1)
  {
    std::cout << "Can't read file " << fn << std::endl;
    exit(-1);
  }

  // store loss
  found = fn.find_last_of(".");
  std::string lossFile = fn.substr(0, found) + ".loss";
  //std::cout << lossFile << std::endl;
  Eigen::readBinary(lossFile.c_str(), allLoss);

  // preload features
  if (PRELOAD)
      Eigen::readBinary(featFile.c_str(), features);

  return gtID;
}

int proposalSolver::featureVector(const vectori& y, vectord& phi)
{
  if (!PRELOAD)
      Eigen::readBinary(featFile.c_str(), features);

  phi.resize(_N);
  for (int i = 0; i < _N; ++i)
    phi[i] = (double) features(y[0], i);

  if (!PRELOAD)
       features.resize(0,_N);
  return 1;
}

vectori proposalSolver::infer(const vectord& weights)
{
  if (!PRELOAD)
      Eigen::readBinary(featFile.c_str(), features);

  Eigen::VectorXf w(_N);
  for (int i = 0; i < _N; ++i)
    w(i) = (float) weights[i];

  Eigen::VectorXf f = features * w + allLoss;
  int max_id;
  f.maxCoeff(&max_id);
  vectori labeling(1, max_id);

  if (!PRELOAD)
       features.resize(0,_N);
  return labeling;
}

double proposalSolver::loss(const vectori& labeling)
{
  double l = 1 - allLoss(labeling[0]);
  return l;
}
