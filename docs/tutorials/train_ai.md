# Training an AI Model with AK CODE

This tutorial shows how to define and train a neural network using AK CODE's built-in AI capabilities.

## What You'll Build

A neural network classifier that can recognize handwritten digits (MNIST-style).

## Step 1: Import the AI Module

```
bring in ai tensor
bring in ai model
bring in ai optimizer
```

## Step 2: Define the Model

```
make model called DigitClassifier
    layer input of size 784
    layer dense of size 128 with activation "relu"
    layer dropout of rate 0.2
    layer dense of size 64 with activation "relu"
    layer output of size 10 with activation "softmax"
end
```

This defines a neural network with:
- Input layer: 784 pixels (28x28 image)
- Hidden layer 1: 128 neurons with ReLU activation
- Dropout layer: 20% dropout for regularization
- Hidden layer 2: 64 neurons with ReLU activation
- Output layer: 10 classes (digits 0-9) with softmax

## Step 3: Prepare Training Data

```
let training data = load images from "train-images.idx3-ubyte"
let training labels = load labels from "train-labels.idx1-ubyte"

let test data = load images from "t10k-images.idx3-ubyte"
let test labels = load labels from "t10k-labels.idx1-ubyte"
```

## Step 4: Train the Model

```
train DigitClassifier
    using data training data
    with labels training labels
    for 10 rounds
    with batch size 32
    using optimizer "adam"
    with learning rate 0.001
end
```

## Step 5: Evaluate

```
let correct = 0
let total = 0

for each i from 0 to size of test data minus 1
    let input = item i of test data
    let true label = item i of test labels
    let prediction = DigitClassifier predict on input
    
    if prediction is true label
        correct = correct plus 1
    end
    total = total plus 1
end

let accuracy = correct times 100 divided by total
show "Accuracy:" accuracy "%"
```

## Step 6: Save the Model

```
save DigitClassifier to "digit_classifier.akmodel"
show "Model saved!"
```

## Loading a Saved Model

```
load model from "digit_classifier.akmodel"

let prediction = DigitClassifier predict on my_input
show "Predicted:" prediction
```

## Complete Training Script

```
bring in ai tensor
bring in ai model
bring in ai optimizer
bring in ai loss

make model called DigitClassifier
    layer input of size 784
    layer dense of size 128 with activation "relu"
    layer dropout of rate 0.2
    layer dense of size 64 with activation "relu"
    layer output of size 10 with activation "softmax"
end

let training data = load images from "train-images.idx3-ubyte"
let training labels = load labels from "train-labels.idx1-ubyte"

train DigitClassifier
    using data training data
    with labels training labels
    for 10 rounds
    with batch size 32
    using optimizer "adam"
    with learning rate 0.001
end

save DigitClassifier to "digit_classifier.akmodel"
show "Training complete!"
```

## Key Concepts

- **Layers**: Building blocks of neural networks
- **Activation functions**: ReLU, sigmoid, tanh, softmax
- **Optimizers**: SGD, Adam, RMSProp
- **Loss functions**: Cross-entropy, MSE
- **Batch size**: Number of samples per training step
- **Epochs/Rounds**: Complete passes through the training data
