"""
Lung Cancer Detection - Model Architecture
Mirrors the NovelHybridEnsembleImproved from the notebook.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import timm
import torchvision.models as models


class ImprovedCustomCNN(nn.Module):
    """
    Improved Custom CNN for micro-nodule detection.
    Key innovations:
    1. Only 2 MaxPool layers (preserves small nodule details)
    2. Residual connections for better gradient flow
    3. Batch normalization after each conv
    4. Squeeze-and-Excitation blocks for channel attention
    """
    def __init__(self, in_channels=3, out_features=128):
        super(ImprovedCustomCNN, self).__init__()

        # Stage 1: Preserve resolution
        self.conv1 = nn.Sequential(
            nn.Conv2d(in_channels, 32, kernel_size=3, stride=1, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),
            nn.Conv2d(32, 32, kernel_size=3, stride=1, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),
        )
        self.pool1 = nn.MaxPool2d(2, stride=2)  # 224 → 112

        # Stage 2: Extract mid-level features
        self.conv2 = nn.Sequential(
            nn.Conv2d(32, 64, kernel_size=3, stride=1, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
            nn.Conv2d(64, 64, kernel_size=3, stride=1, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
        )
        self.pool2 = nn.MaxPool2d(2, stride=2)  # 112 → 56

        # Stage 3: High-level features (no more pooling!)
        self.conv3 = nn.Sequential(
            nn.Conv2d(64, 128, kernel_size=3, stride=1, padding=1),
            nn.BatchNorm2d(128),
            nn.ReLU(inplace=True),
            nn.Conv2d(128, 128, kernel_size=3, stride=1, padding=1),
            nn.BatchNorm2d(128),
            nn.ReLU(inplace=True),
        )

        # Stage 4: Squeeze-and-Excitation block (channel attention)
        self.se = nn.Sequential(
            nn.AdaptiveAvgPool2d(1),
            nn.Flatten(),
            nn.Linear(128, 32),
            nn.ReLU(inplace=True),
            nn.Linear(32, 128),
            nn.Sigmoid()
        )

        # Global feature aggregation
        self.global_pool = nn.AdaptiveAvgPool2d(1)
        self.fc = nn.Sequential(
            nn.Dropout(0.3),
            nn.Linear(128, out_features),
            nn.BatchNorm1d(out_features),
            nn.ReLU(inplace=True)
        )

    def forward(self, x):
        out = self.conv1(x)
        out = self.pool1(out)
        out = self.conv2(out)
        out = self.pool2(out)
        out = self.conv3(out)

        # Squeeze-and-Excitation
        se_weights = self.se(out)
        out = out * se_weights.unsqueeze(-1).unsqueeze(-1)

        # Global pooling and output
        out = self.global_pool(out)
        out = out.flatten(1)
        out = self.fc(out)

        return out


class NovelHybridEnsembleImproved(nn.Module):
    """
    Improved Novel Hybrid Ensemble for Lung Cancer Classification

    Architecture:
    - Branch 1: Vision Transformer (pre-trained) → Global context
    - Branch 2: DenseNet121 (pre-trained) → Deep hierarchical features
    - Branch 3: EfficientNet-B0 (pre-trained) → Efficient balanced features
    - Branch 4: Improved Custom CNN (scratch) → Micro-nodule specialization
    """
    def __init__(self, num_classes=4, use_pretrained=False):
        super(NovelHybridEnsembleImproved, self).__init__()

        # Branch 1: Vision Transformer
        self.vit = timm.create_model(
            'vit_large_patch16_224',
            pretrained=use_pretrained,
            num_classes=0
        )
        vit_features = self.vit.num_features  # 1024

        # Branch 2: DenseNet121
        densenet = models.densenet121(
            weights=models.DenseNet121_Weights.DEFAULT if use_pretrained else None
        )
        self.densenet_features = densenet.features
        densenet_features_out = 1024

        # Branch 3: EfficientNet-B0
        self.efficientnet = timm.create_model(
            'efficientnet_b0',
            pretrained=use_pretrained,
            num_classes=0
        )
        efficientnet_features = self.efficientnet.num_features  # 1280

        # Branch 4: Improved Custom CNN
        self.custom_cnn = ImprovedCustomCNN(in_channels=3, out_features=256)
        custom_features = 256

        # Total combined features
        total_features = vit_features + densenet_features_out + efficientnet_features + custom_features

        # Adaptive Fusion Module
        self.fusion_gate = nn.Sequential(
            nn.Linear(total_features, total_features // 4),
            nn.ReLU(),
            nn.Linear(total_features // 4, total_features),
            nn.Sigmoid()
        )

        # Final Classifier
        self.classifier = nn.Sequential(
            nn.Linear(total_features, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(inplace=True),
            nn.Dropout(0.5),

            nn.Linear(512, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),

            nn.Linear(256, 128),
            nn.BatchNorm1d(128),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),

            nn.Linear(128, num_classes)
        )

    def forward(self, x):
        vit_feats = self.vit(x)
        densenet_feats = self._forward_densenet(x)
        efficient_feats = self.efficientnet(x)
        custom_feats = self.custom_cnn(x)

        combined = torch.cat([vit_feats, densenet_feats, efficient_feats, custom_feats], dim=1)

        gate_weights = self.fusion_gate(combined)
        gated_features = combined * gate_weights

        output = self.classifier(gated_features)
        return output

    def _forward_densenet(self, x):
        features = self.densenet_features(x)
        features = F.relu(features, inplace=True)
        features = F.adaptive_avg_pool2d(features, (1, 1))
        features = torch.flatten(features, 1)
        return features
