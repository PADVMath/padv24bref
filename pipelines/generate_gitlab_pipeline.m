% Copyright 2025 The MathWorks, Inc.

function generate_gitlab_pipeline(workspace, projectRelativePath, matlabInstallationLocation, runnerTags, build_folder)
    arguments
        workspace = pwd;
        projectRelativePath = "";
        matlabInstallationLocation = "matlab_bin_path";
        runnerTags = "gitlab_runner_tag";
        build_folder = "_build_"
    end
    cp = openProject(strjoin({workspace,projectRelativePath} , filesep));
    op = padv.pipeline.GitLabOptions;
    % op.PipelineArchitecture = "IndependentModelPipelines"; # SingleStage, SerialStages, SerialStagesGroupPerTask
    op.PipelineArchitecture = "IndependentModelPipelines";
    op.GeneratorVersion = 2;
    op.MatlabInstallationLocation = matlabInstallationLocation;
    op.Tags = runnerTags;
    op.GeneratedPipelineDirectory = build_folder;
    op.StopOnStageFailure = true;
    op.RunprocessCommandOptions.GenerateJUnitForProcess = true;
    op.ReportPath = "$PROJECTROOT$/PA_Results/Report/PadvReport";
    op.ReportFormat = "html";
    op.ProjectRelativePath = projectRelativePath;

    % Docker image settings
    % examples: "matlab", "matlab-batch", "xvfb-run -a matlab", "xvfb-run -a matlab-batch"
    % op.MatlabLaunchCmd = "xvfb-run -a matlab-batch";
    op.MatlabLaunchCmd = "xvfb-run matlab-batch";
    op.MatlabStartupOptions = "";
    op.AddBatchStartupOption = false;
    padv.pipeline.generatePipeline(op, "CIPipeline");
end