/*  This file is part of Structured Prediction (SP) - http://www.alexander-schwing.de/
 *
 *  Structured Prediction (SP) is free software: you can
 *  redistribute it and/or modify it under the terms of the GNU General
 *  Public License as published by the Free Software Foundation, either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  Structured Prediction (SP) is distributed in the hope
 *  that it will be useful, but WITHOUT ANY WARRANTY; without even the
 *  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 *  PURPOSE. See the GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Structured Prediction (SP).
 *  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Copyright (C) 2010-2013  Alexander G. Schwing  [http://www.alexander-schwing.de/]
 */

//Author: Alexander G. Schwing

/*  ON A PERSONAL NOTE: I spent a significant amount of time to go through
 *  both, theoretical justifications and coding of this framework.
 *  I hope the package is useful for your task. Any citations, requests,
 *  feedback, donations and support would be greatly appreciated.
 *  Thank you for contacting me!
 */
#include <iostream>
#include <vector>
#include <cmath>
#include <cstdlib>
#include <stdio.h>
#include <string.h>
#include <mpi.h>
#include <omp.h>
#include <fstream>

#include "gurobi_c++.h"

#include "Timer.h"

#include "TrainingSample.h"

#ifdef USE_ON_WINDOWS
#include <io.h>
void TraverseDirectory(const std::string& path, std::string& pattern, bool subdirectories, std::vector<std::string>& fileNames) {
	struct _finddatai64_t data;
	std::string fname = path + "\\" + pattern;
	// start the finder -- on error _findfirsti64() will return -1, otherwise if no
	// error it returns a handle greater than -1.
	intptr_t h = _findfirsti64(fname.c_str(),&data);
        int num = 0;
	if(h >= 0) {
		do {
			if( (data.attrib & _A_SUBDIR) ) {
				if( subdirectories && strcmp(data.name,".") != 0 && strcmp(data.name,"..") != 0) {
					fname = path + "\\" + data.name;
					TraverseDirectory(fname,pattern,true, fileNames);
				}
			} else {
				fileNames.push_back(path + "\\" + data.name);
			}
			num ++;
		} while( _findnexti64(h,&data) == 0);

		_findclose(h);
	}
}
#else
#include <dirent.h>
#include <fnmatch.h>
void TraverseDirectory(const std::string& path, std::string& pattern, bool subdirectories, std::vector<std::string>& fileNames) {
	DIR *dir, *tstdp;
    struct dirent *dp;

    //open the directory
    if((dir  = opendir(path.c_str())) == NULL)
    {
		std::cout << "Error opening " << path << std::endl;
        return;
    }

    while ((dp = readdir(dir)) != NULL)
    {
        tstdp=opendir(dp->d_name);

		if(tstdp) {
			closedir(tstdp);
			if(subdirectories) {
				//TraverseDirectory(
			}
		} else {
			if(fnmatch(pattern.c_str(), dp->d_name, 0)==0) {
				std::string tmp(path);
				tmp.append("/").append(dp->d_name);
				fileNames.push_back(tmp);
				//std::cout << fileNames.back() << std::endl;
			}
		}
    }

    closedir(dir);
    return;
}
#endif

struct MarginRescalingData {
	int GlobalSampleID;
	int Successful;
	std::vector<double> featureDiffAndLoss;
	MarginRescalingData(size_t sz) : GlobalSampleID(-1), Successful(0) {
		featureDiffAndLoss.assign(sz, 0.0);
	}
};

class TrainingData {
	struct TrainingDataParams* params;
	std::vector<TrainingSample*> Data;
public:
	TrainingData() {};
	~TrainingData() {
		for(std::vector<TrainingSample*>::iterator it=Data.begin(),it_e=Data.end();it!=it_e;++it) {
			delete *it;
		}
	};

	int LoadData(int myID, int ClusterSize, struct TrainingDataParams* params) {
		int numFeatures = 0;
		this->params = params;
		for(int k=myID, k_e=int(params->SampleData.size());k<k_e;k+=ClusterSize) {
			TrainingSample* tmp = new TrainingSample();
			numFeatures = tmp->Load(params->SampleData[k]);
			Data.push_back(tmp);
		}
		return numFeatures;
	}
	int MaxMarginRescaling(int myID, int ClusterSize, std::vector<double>& w, std::vector<struct MarginRescalingData*>& MRData, double time) {
		int numSamplesSuccessful = 0;
		int k_e = int(Data.size());
		MRData.assign(k_e, NULL);
#pragma omp parallel
{
		int numSamples_local = 0;
#pragma omp for nowait schedule(dynamic,1)
		for(int k=0;k<k_e;++k) {
			int res = Data[k]->MarginRescaling(w, time);
			MRData[k] = new struct MarginRescalingData(w.size()+1);
			MRData[k]->GlobalSampleID = myID + k*ClusterSize;
			if(res==0) {
				++numSamples_local;
				Data[k]->AddFeatureDiffAndLoss(MRData[k]->featureDiffAndLoss, w);
				MRData[k]->Successful = 1;
			}
		}
#pragma omp critical
{
		numSamplesSuccessful += numSamples_local;
}
}
		return numSamplesSuccessful;
	}
};

class QPSolver {
	GRBEnv *env;
	GRBModel *model;
	GRBVar* vars;
public:
	QPSolver() : env(NULL), model(NULL) {};
	~QPSolver() {
		if(model!=NULL)
			delete model;
		model = NULL;
		if(env!=NULL)
			delete env;
		env = NULL;
	};

	int InitializeSolver(int numFeatures, double C, size_t numSamples) {
		std::cout << "Initializing Solver" << std::endl;
		try {
			env = new GRBEnv();

			model = new GRBModel(*env);
			model->getEnv().set(GRB_IntParam_OutputFlag, 0);
			model->getEnv().set(GRB_DoubleParam_BarConvTol, 1e-2);

			vars = model->addVars(numFeatures+int(numSamples));
			model->update();

			for(int k=0;k<numFeatures;++k) {
				vars[k].set(GRB_DoubleAttr_LB, -GRB_INFINITY);
				//vars[k].set(GRB_DoubleAttr_LB, 0.0);
				vars[k].set(GRB_DoubleAttr_Obj, 0.0);
				vars[k].set(GRB_CharAttr_VType, 'C');
			}
			for(size_t k=numFeatures;k<numFeatures+numSamples;++k) {
				vars[k].set(GRB_DoubleAttr_LB, 0.0);
				vars[k].set(GRB_CharAttr_VType, 'C');
			}

			GRBQuadExpr obj = 0;
			for(int k=0;k<numFeatures;++k) {
				obj += 0.5*vars[k]*vars[k];
			}
			for(size_t k=numFeatures;k<numFeatures+numSamples;++k) {
				obj += (C/double(numSamples))*vars[k];
			}
			model->setObjective(obj, GRB_MINIMIZE);
			model->update();
		} catch (GRBException e) {
			std::cout << "Error number: " << e.getErrorCode() << std::endl;
			std::cout << e.getMessage() << std::endl;
			return -1;
		} catch (...) {
			std::cout << "Error during initialization." << std::endl;
			return -1;
		}
		return 0;
	}
	int AddConstraintNoCheck(struct MarginRescalingData* tmp) {
		GRBLinExpr expr = 0;
		int numFeatures = int(tmp->featureDiffAndLoss.size()) - 1;
		for(int k=0;k<numFeatures;++k) {
			expr += tmp->featureDiffAndLoss[k]*vars[k];
		}
		expr += vars[numFeatures+tmp->GlobalSampleID];
		model->addConstr(expr >= tmp->featureDiffAndLoss[numFeatures]);
		model->update();
		return 0;
	}
	int AddConstraint(std::vector<struct MarginRescalingData*>& MRData, std::vector<double>& w, std::vector<double>& xi) {
		int numFeatures = int(w.size());
		int added = 0;
		for(std::vector<struct MarginRescalingData*>::iterator iter=MRData.begin(),iter_e=MRData.end();iter!=iter_e;++iter) {
			int Sample = (*iter)->GlobalSampleID;
			GRBLinExpr expr = 0;
			double termination = 0.0;
			for(int k=0;k<numFeatures;++k) {
				expr += (*iter)->featureDiffAndLoss[k]*vars[k];
				termination += w[k]*(*iter)->featureDiffAndLoss[k];
			}
			if((*iter)->featureDiffAndLoss[numFeatures] - termination <= xi[Sample] + 1e-5) {
				//std::cout << "Sample " << Sample << ": \\delta(\\hat y, y_i) - w^T(\\phi(x,y_i) - \\phi(x,\\hat y)) <= x_i + 1e-5: " << std::endl;
				//std::cout << (*iter)->featureDiffAndLoss[numFeatures] << " - " << termination << " <= " << xi[Sample] << " + 1e-5" << std::endl;
				//continue;
			}
			expr += vars[numFeatures+Sample];
			model->addConstr(expr >= (*iter)->featureDiffAndLoss[numFeatures]);
			++added;
		}
		model->update();
		return added;
	}
	double Solve(std::vector<double>& w, std::vector<double>& xi) {
		model->optimize();

		for(size_t k=0;k<w.size();++k) {
			w[k] = vars[k].get(GRB_DoubleAttr_X);
		}
		for(size_t k=0;k<xi.size();++k) {
			xi[k] = vars[k+w.size()].get(GRB_DoubleAttr_X);
		}

		//Potentially remove constraints if they haven't been active for a while
		//see internal sources for those improvements

		return model->get(GRB_DoubleAttr_ObjVal);
	}
};

struct InputData {
	const char* dir;
	char* InputModel;
	char* OutputModel;
	char* DataFile;
    char* pattern;
	int MaxIterations;
	int ItCounter;
	double C;
	double time;
};

int ParseInput(int argc, char** argv, struct InputData& OD) {
	for(int k=1;k<argc;++k) {
		if(::strcmp(argv[k], "-d")==0 && k+1!=argc) {
			OD.dir = argv[++k];
		} else if(::strcmp(argv[k], "-m")==0 && k+1!=argc) {
			OD.InputModel = argv[++k];
		} else if(::strcmp(argv[k], "-o")==0 && k+1!=argc) {
			OD.OutputModel = argv[++k];
		} else if(::strcmp(argv[k], "-f")==0 && k+1!=argc) {
			OD.DataFile = argv[++k];
		} else if(::strcmp(argv[k], "-i")==0 && k+1!=argc) {
			OD.MaxIterations = atoi(argv[++k]);
		} else if(::strcmp(argv[k], "-c")==0 && k+1!=argc) {
			OD.C = double(atof(argv[++k]));
		} else if(::strcmp(argv[k], "-t")==0 && k+1!=argc) {
			OD.time = double(atof(argv[++k]));
		} else if(::strcmp(argv[k], "-n")==0 && k+1!=argc) {
			OD.ItCounter = atoi(argv[++k]);
		} else if(::strcmp(argv[k], "-p")==0 && k+1!=argc) {
            OD.pattern = argv[++k];
	    }
	}
	return 0;
}

int InitializeModel(std::vector<double>& theta, const char* fn, int myID, QPSolver* Solver, std::vector<struct MarginRescalingData*>& MRDataAll) {
	int vecSize = 0;
	std::ifstream ifs(fn, std::ios_base::in | std::ios_base::binary);
	if(!ifs.is_open()) {
		std::cout << "Model not found." << std::endl;
		return -1;
	}
	ifs.read((char*)&vecSize, sizeof(int));
	if(vecSize!=int(theta.size())) {
		std::cout << "Model does not match feature size." << std::endl;
		ifs.close();
		return -1;
	} else {
		ifs.read((char*)&theta[0], vecSize*sizeof(double));
		if(myID==0) {
			struct MarginRescalingData* tmp = new struct MarginRescalingData(vecSize+1);
			ifs.read((char*)&tmp->GlobalSampleID, sizeof(int));
			ifs.read((char*)&tmp->featureDiffAndLoss[0], (vecSize+1)*sizeof(double));
			size_t numConAdded = 0;
			while(!ifs.eof()) {
				MRDataAll.push_back(tmp);
				Solver->AddConstraintNoCheck(tmp);
				++numConAdded;
				tmp = new struct MarginRescalingData(vecSize+1);
				ifs.read((char*)&tmp->GlobalSampleID, sizeof(int));
				ifs.read((char*)&tmp->featureDiffAndLoss[0], (vecSize+1)*sizeof(double));
			}
			delete tmp;
			std::cout << "  " << numConAdded << " constraint(s) found." << std::endl;
		}
		ifs.close();
		return 0;
	}
	return 0;
}

int RemoveFiles(std::vector<std::string>& fileNames, const char* fn) {
	std::ifstream ifs(fn, std::ios_base::in);
	std::string imageName;
	ifs >> imageName;
	std::vector<size_t> FoundIndices;
	while(imageName.size()>0) {
		std::string pattern = imageName.substr(0, imageName.find_last_of("."));
		for(size_t ix=0;ix<fileNames.size();++ix) {
#ifdef USE_ON_WINDOWS
			std::string tmp = fileNames[ix].substr(fileNames[ix].find_last_of("\\")+1, fileNames[ix].find_last_of(".") - fileNames[ix].find_last_of("\\") - 1);
#else
			std::string tmp = fileNames[ix].substr(fileNames[ix].find_last_of("/")+1, fileNames[ix].find_last_of(".") - fileNames[ix].find_last_of("/") - 1);
#endif
			if(tmp==pattern) {
				FoundIndices.push_back(ix);
				break;
			}
		}
		if(ifs.eof()) {
			break;
		}
		ifs >> imageName;
	}
	ifs.close();
	std::vector<std::string> tmp;
	for(size_t ix=0;ix<FoundIndices.size();++ix) {
		tmp.push_back(fileNames[FoundIndices[ix]]);
	}
	fileNames = tmp;
	return 0;
}

int MergeMaxMarginData(int myID, int ClusterSize, size_t numSamples, int numFeatures, std::vector<struct MarginRescalingData*>& MRData, std::vector<struct MarginRescalingData*>& MRDataMerged) {
	std::vector<double> data(numSamples*(numFeatures+2), 0.0);
	for(std::vector<struct MarginRescalingData*>::iterator iter=MRData.begin(),iter_e=MRData.end();iter!=iter_e;++iter) {
		if((*iter)->Successful>0) {
			data[(*iter)->GlobalSampleID*(numFeatures+2)] = double((*iter)->GlobalSampleID);
			memcpy((char*)&data[(*iter)->GlobalSampleID*(numFeatures+2)+1], (char*)&(*iter)->featureDiffAndLoss[0], sizeof(double)*(numFeatures+1));
		} else {
			data[(*iter)->GlobalSampleID*(numFeatures+2)] = -1.0;
		}
	}
	std::vector<double> dataMerged(int(numSamples)*(numFeatures+2), 0.0);
	int numSuccessful = 0;
	MPI::COMM_WORLD.Reduce(&data[0], &dataMerged[0], int(numSamples)*(numFeatures+2), MPI::DOUBLE, MPI::SUM, 0);
	if(myID==0) {
		for(size_t k=0;k<numSamples;++k) {
			if(dataMerged[k*(numFeatures+2)]>=0.0) {
				++numSuccessful;
				struct MarginRescalingData* tmp = new struct MarginRescalingData(numFeatures+1);
				tmp->Successful = 1;
				tmp->GlobalSampleID = int(dataMerged[k*(numFeatures+2)]);
				std::copy(&dataMerged[k*(numFeatures+2)]+1, &dataMerged[k*(numFeatures+2)]+numFeatures+2, &tmp->featureDiffAndLoss[0]);
				MRDataMerged.push_back(tmp);
			}
		}
	}
	return numSuccessful;
}

int main(int argc, char** argv) {
#ifdef USE_ON_WINDOWS
	std::string GroundTruthFolder = "";
#else
	std::string GroundTruthFolder = "";
#endif

	omp_set_num_threads(8);

	InputData inp;
	inp.dir = GroundTruthFolder.c_str();
	inp.OutputModel = NULL;
	inp.InputModel = NULL;
	inp.DataFile = NULL;
	inp.MaxIterations = 10;
	inp.ItCounter = 0;
	inp.C = 1;
	inp.time = -1;
    inp.pattern = NULL;
	ParseInput(argc, argv, inp);

	//std::string pattern = "*.pos60";
    std::string pattern(inp.pattern);
	std::vector<std::string> fileNames;
	std::string folder(inp.dir);
	TraverseDirectory(folder, pattern, false, fileNames);
	if(inp.DataFile!=NULL) {
		RemoveFiles(fileNames, inp.DataFile);
	}

	if(fileNames.size()==0) {
		std::cout << "No files to process." << std::endl;
		return 0;
	}

	struct TrainingDataParams params;
	for(size_t k=0;k<fileNames.size();++k) {
		struct SampleParams* s = new struct SampleParams;
		s->fn = fileNames[k];
		params.SampleData.push_back(s);
	}

	MPI::Init(argc, argv);
	int ClusterSize = MPI::COMM_WORLD.Get_size();
	int myID = MPI::COMM_WORLD.Get_rank();

	TrainingData Data;
	int numFeatures = Data.LoadData(myID, ClusterSize, &params);
	MPI::COMM_WORLD.Bcast(&numFeatures, 1, MPI::INT, 0);

	QPSolver Solver;
	int retInit;
	if(myID==0) {
		std::cout << "Training Data: (" << fileNames.size() << ")" << std::endl;
		for(size_t k=0;k<fileNames.size();++k) {
			std::cout << "  " << fileNames[k] << std::endl;
		}
		retInit = Solver.InitializeSolver(numFeatures, inp.C, params.SampleData.size());
		MPI::COMM_WORLD.Bcast(&retInit, 1, MPI::INT, 0);
	} else {
		MPI::COMM_WORLD.Bcast(&retInit, 1, MPI::INT, 0);
	}
	if(retInit!=0) {
		MPI::Finalize();
		return 0;
	}

	std::vector<double> w(numFeatures, -1.0);
	std::vector<double> xi(params.SampleData.size(), 0.0);

	std::vector<struct MarginRescalingData*> MRData;
	std::vector<struct MarginRescalingData*> MRDataMerged;
	std::vector<struct MarginRescalingData*> MRDataAll;

	if(inp.InputModel!=NULL) {
		if(InitializeModel(w, inp.InputModel, myID, &Solver, MRDataAll)!=0) {
			MPI::Finalize();
			return 0;
		}
		if(myID==0) {
			std::vector<double> w_tmp(numFeatures, 0.0);
			std::vector<double> xi_tmp(params.SampleData.size(), 0.0);
			Solver.Solve(w_tmp, xi_tmp);
			double diff = 0.0;
			for(int k=0;k<numFeatures;++k) {
				diff += fabs(w[k]-w_tmp[k]);
			}
			std::cout << "  Difference: " << diff << std::endl;
		}
	}

	CPrecisionTimer CTmr;
	int added = 0;
	double obj = 0.0;
	int numSamplesSuccessful;
	for(int iter=inp.ItCounter;iter<inp.MaxIterations;++iter) {
		if(myID==0) {
			std::cout << "Iteration: " << iter << std::endl;
			CTmr.Start();
			MRDataMerged.clear();
		}
		for(size_t k=0;k<MRData.size();++k) {
			delete MRData[k];
		}
		MRData.clear();
		numSamplesSuccessful = 0;
		int numSamplesSuccessful_local = Data.MaxMarginRescaling(myID, ClusterSize, w, MRData, inp.time);
		MPI::COMM_WORLD.Allreduce(&numSamplesSuccessful_local, &numSamplesSuccessful, 1, MPI::INT, MPI::SUM);
		if(numSamplesSuccessful==0) {
			if(myID==0) {
				std::cout << std::endl << "No successful samples." << std::endl;
			}
			break;
		} else {
			int sanityCheck = MergeMaxMarginData(myID, ClusterSize, params.SampleData.size(), numFeatures, MRData, MRDataMerged);
			if(myID==0) {
				assert(sanityCheck==numSamplesSuccessful);
				std::cout << numSamplesSuccessful << " successful samples." << std::endl;
				std::cout << "Time for MarginRescaling: " << CTmr.Stop() << std::endl;
			}
		}

		if(myID==0) {
			added = Solver.AddConstraint(MRDataMerged, w, xi);
			MRDataAll.insert(MRDataAll.end(), MRDataMerged.begin(), MRDataMerged.end());
			MPI::COMM_WORLD.Bcast(&added, 1, MPI::INT, 0);
			if(added==0) {
				break;
			}
			CTmr.Start();
			obj = Solver.Solve(w, xi);
			std::cout << "Time for solver: " << CTmr.Stop() << std::endl;
			MPI::COMM_WORLD.Bcast(&w[0], int(w.size()), MPI::DOUBLE, 0);
			std::cout << "Objective: " << obj << std::endl;
			std::cout << "w = [";
			for(size_t k=0;k<w.size();++k) {
				std::cout << w[k] << " ";
			}
			std::cout << "]" << std::endl;
			if(inp.OutputModel!=NULL) {
				char fn[257];
				sprintf(fn, "%s.%d", inp.OutputModel, iter);
				std::ofstream ofs(fn, std::ios_base::out | std::ios_base::binary);
				ofs.write((char*)&numFeatures, sizeof(int));
				ofs.write((char*)&w[0], numFeatures*sizeof(double));
//				for(size_t k=0;k<MRDataAll.size();++k) {
//					ofs.write((char*)&MRDataAll[k]->GlobalSampleID, sizeof(int));
//					ofs.write((char*)&MRDataAll[k]->featureDiffAndLoss[0], sizeof(double)*(numFeatures+1));
//				}
				ofs.close();
			}
		} else {
			MPI::COMM_WORLD.Bcast(&added, 1, MPI::INT, 0);
			if(added==0) {
				break;
			}
			MPI::COMM_WORLD.Bcast(&w[0], int(w.size()), MPI::DOUBLE, 0);
		}
	}

	if(myID==0) {
		for(size_t k=0;k<MRDataAll.size();++k) {
			delete MRDataAll[k];
		}
		MRDataAll.clear();
		MRDataMerged.clear();
	}
	for(size_t k=0;k<MRData.size();++k) {
		delete MRData[k];
	}
	MRData.clear();
	for(size_t k=0;k<params.SampleData.size();++k) {
		delete params.SampleData[k];
	}

	MPI::Finalize();

	return 0;
}
