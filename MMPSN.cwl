#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: "sinaiiidgst/mmpsn:latest2"

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

baseCommand: ["python3", "/bin/predict_psn_subgroup.py"]

outputs:
  Predicted_Classes:
    type: File
    outputBinding:
      glob: "Predicted_class.csv"