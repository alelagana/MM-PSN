#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: "sinaiiidgst/mmpsn:latest2"

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

  PredictedTrans:
    type: File
    inputBinding:
      position: 4

baseCommand: ["Rscript", "/bin/Daphni2_CNV_Risk_Score_Input_Generation.R"]

outputs:
  Predicted_Classes:
    type: File
    outputBinding:
      glob: "CNV_risk_score_input.csv"

  Predicted_Trans_Final:
    type: File
    outputBinding:
      glob: "predicted_trans_final.csv"

