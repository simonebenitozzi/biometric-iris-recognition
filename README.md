# Biometric Iris Recognition

This repository contains the code and resources related to the analysis of the limitations of biometrics, specifically in iris recognition, when certain pathological conditions, such as coloboma, are present. The project explores the implications of these limitations, both in terms of algorithmic assumptions and ethical considerations.

## Abstract

The objective of this project is to analyze the limits of biometrics, focusing on the recognition of the iris under specific pathological conditions that challenge the assumptions underlying biometric algorithms. These conditions, such as coloboma, result in the deformation of the pupil and compression of the iris, leading to a loss of characteristic information. Traditional biometric algorithms, designed to detect internal circles to distinguish the pupil from the iris and extract information, face difficulties in such cases.

Due to the rarity of coloboma, it was not possible to obtain a dataset of individuals affected by this condition to analyze the physical changes over time. Consequently, a data augmentation operation was performed on a dataset of healthy eyes to artificially simulate the effects of coloboma.

Several tests were conducted on the obtained data, initially to evaluate the effectiveness of the existing segmentation algorithm with the aim of improving it and achieving better results, which will be presented in detail. Subsequently, an analysis was carried out to determine to what extent a subject can be uniquely recognized in the presence of coloboma as the condition progressively worsens, making the detection itself more challenging.

## Repository Directories

- **Error Detection:** Contains code related to error detection and handling in the biometric iris recognition system.

- **Matching:** Contains code for matching and comparing iris patterns using various algorithms and techniques.

- **Normal_encoding:** Includes code for encoding and normalizing iris images for biometric analysis.

- **Old Functions:** Holds deprecated or older versions of functions that were used in the development process.

- **Pupil_Resizing:** Contains code for resizing and manipulating the pupil region in iris images.

- **Segmentation:** Includes code for segmenting the iris region from the overall eye image using different segmentation algorithms.

- **Template Coding:** Contains code for encoding and decoding iris templates for recognition purposes.

- **database:** Stores the dataset of healthy eyes used for data augmentation and simulation of coloboma effects.

Please refer to the respective directories for detailed information and usage instructions for each component.

## Requirements

- Python 3.7 or above
- Additional package requirements are listed in the `requirements.txt` file in each directory.

## Usage

1. Clone the repository:

   ```
   git clone https://github.com/your-username/biometric-iris-recognition-coloboma.git
   ```

2. Navigate to the desired directory containing the relevant code.

3. Follow the instructions provided in the specific directory's readme file for setup and usage details.
