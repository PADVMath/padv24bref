% Copyright 2025 The MathWorks, Inc.

function generate_github_pipeline(workspace, projectRelativePath, matlabInstallationLocation, runnerLabels, build_folder)
    arguments
        workspace = pwd;
        projectRelativePath = "";
        matlabInstallationLocation = "matlab_bin_path";
        runnerLabels = "padvRunnerGithubPub"; %"padv24brefNewRunner";
        build_folder = "_build_"
    end
    cp = openProject(strcat(workspace,filesep,projectRelativePath));
    op = padv.pipeline.GitHubOptions;
    op.PipelineArchitecture = "IndependentModelPipelines";
    op.GeneratorVersion = 2;
    op.MatlabInstallationLocation = "C:\Program Files\MATLAB\R2024b\bin";     % "C:/Program Files/MATLAB/R2024b/bin";
    op.RunnerLabels = runnerLabels;                                 % "padv_win_agents";
    op.GeneratedPipelineDirectory = build_folder;                   % "_build_";
    op.StopOnStageFailure = true;
    op.RunprocessCommandOptions.GenerateJUnitForProcess = true;
    op.ReportPath = "$PROJECTROOT$/PA_Results/Report/PadvReport";
    op.ProjectRelativePath = projectRelativePath;                       % "" or "level1-a/level2/ProcessAdvisorProjectReferenceExample/"
    
    % Docker image settings
    op.UseMatlabPlugin = false;
    % examples: "matlab", "matlab-batch", "xvfb-run -a matlab", "xvfb-run -a matlab-batch"
    op.MatlabLaunchCmd = "xvfb-run -a matlab-batch";
    op.MatlabStartupOptions = "";
    op.AddBatchStartupOption = false;
    padv.pipeline.generatePipeline(op, "CIPipeline");
end
