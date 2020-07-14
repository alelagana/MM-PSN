#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: "sinaiiidgst/mmpsn:test"

inputs:
  ParsedCNVs:
    type: File
    inputBinding:
      position: 1

  Cytoband:
    type: File
    inputBinding:
      position: 2

  SampleName:
    type: string
    inputBinding:
      position: 3

baseCommand: ["Rscript", "/bin/Daphni2_CNV_Risk_Score_Input_Generation.R"]

outputs:
  Predicted_Classes:
    type: File
    outputBinding:
      glob: "CNV_risk_score_input.txt"