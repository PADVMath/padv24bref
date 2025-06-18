% Copyright 2025 The MathWorks, Inc.

function generate_gitlab_pipeline(workspace, projectToRepoPath, matlabInstallationLocation, tags, build_folder)
    arguments
        workspace = pwd;
        projectToRepoPath = "";
        matlabInstallationLocation = "matlab_bin_path";
        tags = "gitlab_runner_tags";
        build_folder = "_build_"
    end
    cp = openProject(strjoin({workspace,projectToRepoPath} , filesep));
    op = padv.pipeline.GitLabOptions;
    % op.PipelineArchitecture = "IndependentModelPipelines"; # SingleStage, SerialStages, SerialStagesGroupPerTask
    op.PipelineArchitecture = "IndependentModelPipelines";
    op.GeneratorVersion = 2;
    op.MatlabInstallationLocation = matlabInstallationLocation;
    op.Tags = tags;
    op.GeneratedPipelineDirectory = build_folder;
    op.StopOnStageFailure = true;
    op.RunprocessCommandOptions.GenerateJUnitForProcess = true;
    op.ReportPath = "$PROJECTROOT$/PA_Results/Report/PadvReport";
    op.ProjectToRepoPath = projectToRepoPath;

    % Docker image settings
    % examples: "matlab", "matlab-batch", "xvfb-run -a matlab", "xvfb-run -a matlab-batch"
    % op.MatlabLaunchCmd = "xvfb-run -a matlab-batch";
    op.MatlabLaunchCmd = "matlab-batch";
    op.MatlabStartupOptions = "";
    op.AddBatchStartupOption = false;
    padv.pipeline.generatePipeline(op, "CIPipeline");
end