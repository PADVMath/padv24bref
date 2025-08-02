% Copyright 2025 The MathWorks, Inc.

function generate_jenkins_pipeline2( )
    workspace = getenv('WORKSPACE');      % Reading Jenkins workspace environment variable
    supportPackageRoot = getenv('MW_SUPPORT_PACKAGE_ROOT');
    relativeProjectPath = getenv('MW_RELATIVE_PROJECT_PATH');
    pipelineGenDirectory = getenv('MW_PIPELINE_GEN_DIRECTORY');

    cp = openProject(strcat(workspace,filesep,string(relativeProjectPath)));
    op = padv.pipeline.JenkinsOptions;
    % op.PipelineArchitecture = "IndependentModelPipelines"; # SingleStage, SerialStages, SerialStagesGroupPerTask
    op.PipelineArchitecture = "SingleStage";
    op.GeneratorVersion = 2;
    op.SupportPackageRoot = supportPackageRoot;
    op.AgentLabel = "JenkinsAgentMatlabUser";
    op.GeneratedPipelineDirectory = pipelineGenDirectory;
    op.StopOnStageFailure = true;
    op.RunprocessCommandOptions.GenerateJUnitForProcess = true;
    op.ReportPath = "$PROJECTROOT$/PA_Results/Report/ProcessAdvisorReport";
    op.RelativeProjectPath = relativeProjectPath;

    % We can enhance the vaidation now of the options on the matlab side
    op.ArtifactServiceMode = 'azure_blob';         % network/jfrog/s3/azure_blob
    % op.NetworkStoragePath = '<Artifactory network storage path>';
    % op.ArtifactoryUrl = '<JFrog artifactory url>';
    % op.ArtifactoryRepoName = '<JFrog artifactory repo name>';
    % op.S3BucketName = '<AWS S3 bucket name>';
    % op.S3AwsAcessKeyID = '<AWS S3 access key id>';
    op.AzContainerName = 'padvcontainer';
    op.RunnerType = "container";        % default/container
    op.ImageTag = 'slcicd.azurecr.io/slcheck/padv-ci:r2024b_apr25t_ci_spkg20250801'; %'slcicd.azurecr.io/slcheck/padv-ci:r2024b_apr25t_ci_spkg20250730';
    % op.ImageArgs = "<Docker container arguments>";
    
    % Docker image settings
    op.UseMatlabPlugin = false;
    % examples: "matlab", "matlab-batch", "xvfb-run -a matlab", "xvfb-run -a matlab-batch"    
    op.MatlabLaunchCmd = "xvfb-run -a matlab-batch"; 
    op.MatlabStartupOptions = "";
    op.AddBatchStartupOption = false;
    
    padv.pipeline.generatePipeline(op, "CIPipeline");
end
