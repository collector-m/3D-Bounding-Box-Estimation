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
#include "proposalSolver.hpp"


struct SampleParams {
	std::string fn;
};

struct TrainingDataParams {
	std::vector<struct SampleParams*> SampleData;
};

class TrainingSample {
	struct SampleParams* sample;
	std::vector<int> labeling;
	std::vector<int> gt;
	std::vector<double> phi_gt;
public:
	TrainingSample() {};
	~TrainingSample() {};

        proposalSolver propSolver;

	int Load(struct SampleParams* sample) {
		this->sample = sample;
        int numFeatures = _N;
        std::cout << "loading sample: " << sample->fn << std::endl;
        gt = propSolver.load(sample->fn);

		//assign gt and other required data
		phi_gt.assign(numFeatures, 0.0);
		FeatureVector(gt, phi_gt);
		return numFeatures;
	}
	int MarginRescaling(std::vector<double>& w, double time) {
		//compute margin rescaling and assign labeling
        labeling = propSolver.infer(w);
		return 0;
	}
	int FeatureVector(std::vector<int>& y, std::vector<double>& phi) {
		//compute feature vector phi from labeling y
        propSolver.featureVector(y, phi);
		return 0;
	}
	double Loss() {
		double loss = propSolver.loss(labeling);
		//compute loss of labeling w.r.t. gt
		return loss;
	}
	int AddFeatureDiffAndLoss(std::vector<double>& featureDiffAndLoss, std::vector<double>& w) {
		int numFeatures = int(featureDiffAndLoss.size())-1;
		std::vector<double> phi_y(numFeatures, 0.0);
		FeatureVector(labeling, phi_y);
		for(int k=0;k<numFeatures;++k) {
			featureDiffAndLoss[k] += phi_gt[k] - phi_y[k];
		}
		featureDiffAndLoss[numFeatures] += Loss();
		return 0;
	}
};
