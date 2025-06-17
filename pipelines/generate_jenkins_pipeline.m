% Copyright 2025 The MathWorks, Inc.

function generate_jenkins_pipeline(workspace, projectToRepoPath, matlabInstallationLocation, agentLabel, build_folder)
    arguments
        workspace = pwd;
        projectToRepoPath = "";
        matlabInstallationLocation = "matlab_bin_path";
        agentLabel = "jenkins_agent_label";
        build_folder = "_build_"
    end
    cp = openProject(strjoin({workspace,projectToRepoPath} , filesep));
    op = padv.pipeline.JenkinsOptions;
    % op.PipelineArchitecture = "IndependentModelPipelines"; # SingleStage, SerialStages, SerialStagesGroupPerTask
    op.PipelineArchitecture = "IndependentModelPipelines";
    op.GeneratorVersion = 2;
    op.MatlabInstallationLocation = matlabInstallationLocation;
    op.AgentLabel = agentLabel;
    op.GeneratedPipelineDirectory = build_folder;
    op.StopOnStageFailure = true;
    op.RunprocessCommandOptions.GenerateJUnitForProcess = true;
    op.ReportPath = "$PROJECTROOT$/PA_Results/Report/PadvReport";
    op.ProjectToRepoPath = projectToRepoPath;

    % Docker image settings
    op.UseMatlabPlugin = false;
    % examples: "matlab", "matlab-batch", "xvfb-run -a matlab", "xvfb-run -a matlab-batch"
    % op.MatlabLaunchCmd = "xvfb-run -a matlab-batch";
    op.MatlabLaunchCmd = "matlab-batch";
    op.MatlabStartupOptions = "";
    op.AddBatchStartupOption = false;
    padv.pipeline.generatePipeline(op, "CIPipeline");
end