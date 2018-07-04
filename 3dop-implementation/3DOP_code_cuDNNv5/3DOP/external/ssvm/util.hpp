# pragma once
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <map>
#include <cmath>
#include <boost/algorithm/string.hpp>
#include "Eigen/Dense"

typedef std::vector<float> vectorf;
typedef std::vector<double> vectord;
typedef std::vector<int> vectori;

namespace Eigen{
template<class Matrix>
void writeBinary(const char* filename, const Matrix& matrix)
{
    std::ofstream out(filename, std::ios::out | std::ios::binary | std::ios::trunc);
    typename Matrix::Index rows=matrix.rows(), cols=matrix.cols();
    out.write((char*) (&rows), sizeof(typename Matrix::Index));
    out.write((char*) (&cols), sizeof(typename Matrix::Index));
    out.write((char*) matrix.data(), rows*cols*sizeof(typename Matrix::Scalar) );
    out.close();
}

template<class Matrix>
void readBinary(const char* filename, Matrix& matrix)
{
    std::ifstream in(filename, std::ios::in | std::ios::binary);
    typename Matrix::Scalar rows=0, cols=0;
    in.read((char*) (&rows),sizeof(typename Matrix::Scalar));
    in.read((char*) (&cols),sizeof(typename Matrix::Scalar));
//    std::cout << "rows:" << rows << " cols:" << cols << std::endl;
    matrix.resize(rows, cols);
    in.read( (char *) matrix.data() , rows*cols*sizeof(typename Matrix::Scalar) );
    in.close();
}
}


// IO helper
int readFile(const char* filename, vectorf *data)
{
  std::ifstream fin(filename);
  std::string s;
  std::vector<std::string> fields;
  int width(0), height(0);

  while (true)
  {
    std::getline(fin, s);
    if (s[0] == '#')
      continue;

    split(fields, s, boost::algorithm::is_any_of(" "));
    if (strcmp(fields[0].c_str(), "WIDTH") == 0)
    {
      width = atoi(fields[1].c_str());
    }
    else if (strcmp(fields[0].c_str(), "HEIGHT") == 0)
    {
      height = atoi(fields[1].c_str());
      break;
    }
    else
    {
      std::cout << "Incorrect file header in " << filename << std::endl;
      return -1;
    }
  }

  data->clear();
  for (int j = 0; j < width;  ++j)
  {
    fin >> s;
    data->push_back(atof(s.c_str()));
  }
  fin.close();

  return 1;
}


// IO helper
int readFile(const char* filename, vectori *data)
{
  std::ifstream fin(filename);
  std::string s;
  std::vector<std::string> fields;
  int width(0), height(0);

  while (true)
  {
    std::getline(fin, s);
    if (s[0] == '#')
      continue;

    split(fields, s, boost::algorithm::is_any_of(" "));
    if (strcmp(fields[0].c_str(), "WIDTH") == 0)
    {
      width = atoi(fields[1].c_str());
    }
    else if (strcmp(fields[0].c_str(), "HEIGHT") == 0)
    {
      height = atoi(fields[1].c_str());
      break;
    }
    else
    {
      std::cout << "Incorrect file header in " << filename << std::endl;
      return -1;
    }
  }

  data->clear();
  for (int j = 0; j < width;  ++j)
  {
    fin >> s;
    data->push_back(atoi(s.c_str()));
  }
  fin.close();

  return 1;
}


// IO helper
int readFile(const char* filename, std::vector<vectorf> *data)
{
  std::ifstream fin(filename);
  std::string s;
  std::vector<std::string> fields;
  int width(0), height(0);

  while (true)
  {
    std::getline(fin, s);
    if (s[0] == '#')
      continue;

    split(fields, s, boost::algorithm::is_any_of(" "));
    if (strcmp(fields[0].c_str(), "WIDTH") == 0)
    {
      width = atoi(fields[1].c_str());
    }
    else if (strcmp(fields[0].c_str(), "HEIGHT") == 0)
    {
      height = atoi(fields[1].c_str());
      break;
    }
    else
    {
      std::cout << "Incorrect file header in " << filename << std::endl;
      return -1;
    }
  }

  data->clear();
  for (int i = 0; i < height; ++i)
  {
    vectorf row(width);
    for (int j = 0; j < width;  ++j)
    {
      fin >> s;
      row[j] = atof(s.c_str());
    }
    data->push_back(row);
  }
  fin.close();

  return 1;
}

// IO helper
int readFile(const char* filename, std::vector<std::vector<int> > *data)
{
  std::ifstream fin(filename);
  std::string s;
  std::vector<std::string> fields;
  int width(0), height(0);

  while (true)
  {
    std::getline(fin, s);
    if (s[0] == '#')
      continue;

    split(fields, s, boost::algorithm::is_any_of(" "));
    if (strcmp(fields[0].c_str(), "WIDTH") == 0)
    {
      width = atoi(fields[1].c_str());
    }
    else if (strcmp(fields[0].c_str(), "HEIGHT") == 0)
    {
      height = atoi(fields[1].c_str());
      break;
    }
    else
    {
      std::cout << "Incorrect file header in " << filename << std::endl;
      return -1;
    }
  }

  data->clear();
  for (int i = 0; i < height; ++i)
  {
    std::vector<int> row(width);
    for (int j = 0; j < width;  ++j)
    {
      fin >> s;
      row[j] = atoi(s.c_str());
    }
    data->push_back(row);
  }
  fin.close();

  return 1;
}


// IO helper
template <typename T>
int readMat(const char* filename, std::vector<std::vector<T> > *data)
{
  std::ifstream fin(filename);
  std::string s;
  std::vector<std::string> fields;
  int width(0), height(0);

  while (true)
  {
    std::getline(fin, s);
    if (s[0] == '#')
      continue;

    split(fields, s, boost::algorithm::is_any_of(" "));
    if (strcmp(fields[0].c_str(), "WIDTH") == 0)
    {
      width = atoi(fields[1].c_str());
    }
    else if (strcmp(fields[0].c_str(), "HEIGHT") == 0)
    {
      height = atoi(fields[1].c_str());
      break;
    }
    else
    {
      std::cout << "Incorrect file header in " << filename << std::endl;
      return -1;
    }
  }

  data->clear();
  for (int i = 0; i < height; ++i)
  {
    std::vector<T> row(width);
    if (typeid(T) == typeid(int))
    {
      for (int j = 0; j < width;  ++j)
      {
        fin >> s;
        row[j] = atoi(s.c_str());
      }
    }
    else if (typeid(T) == typeid(float) || typeid(T) == typeid(double))
    {
      for (int j = 0; j < width;  ++j)
      {
        fin >> s;
        row[j] = (T) atof(s.c_str());
      }
    }
    data->push_back(row);
  }
  fin.close();

  return 1;
}


