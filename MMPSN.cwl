#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: "sinaiiidgst/mmpsn:898fad920d3c2f71973c333c8d77e0e4265299e3"

inputs:
  ExpressionFile:
    type: File
    inputBinding:
      position: 1
    label: "Expression TSV for samples you want to score."

  CNVFile:
    type: File
    inputBinding:
      position: 2
    label: "CNV feature file for samples you want to score."

  TranslocationFile:
    type: File
    inputBinding:
      position: 3
    label: "Translocation feature file for samples you want to score."

  Output:
    type: string
    default: "Predicted_class.csv"
    inputBinding:
      position: 4
      valueFrom: "Predicted_class.csv"

baseCommand: ["python3", "/bin/predict_psn_subgroup.py"]

outputs:
  Predicted_Classes:
    type: File
    outputBinding:
      glob: "Predicted_class.csv"