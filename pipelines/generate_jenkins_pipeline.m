% Copyright 2025 The MathWorks, Inc.

function generate_jenkins_pipeline()
    workspace = string(getenv('WORKSPACE'));      % Reading Jenkins workspace environment variable
    supportPackageRoot = string(getenv('MW_SUPPORT_PACKAGE_ROOT'));
    relativeProjectPath = string(getenv('MW_RELATIVE_PROJECT_PATH'));
    remoteBuildCacheName = string(getenv('MW_REMOTE_BUILD_CACHE_NAME'));
    pipelineGenDirectory = string(getenv('MW_PIPELINE_GEN_DIRECTORY'));

    cp = openProject(strcat(workspace,filesep,string(relativeProjectPath)));
    op = padv.pipeline.JenkinsOptions;
    op.AgentLabel = "JenkinsAgentMatlabUser";
    op.PipelineArchitecture = "IndependentModelPipelines";
    op.GeneratorVersion = 2;
    op.SupportPackageRoot = supportPackageRoot;
    op.GeneratedPipelineDirectory = pipelineGenDirectory;
    op.StopOnStageFailure = true;
    op.RunprocessCommandOptions.GenerateJUnitForProcess = true;
    op.ReportPath = "$PROJECTROOT$/PA_Results/Report/ProcessAdvisorReport";
    op.RelativeProjectPath = relativeProjectPath;
    op.RemoteBuildCacheName = remoteBuildCacheName;

    op.ArtifactServiceMode = 'azure_blob';         % network/jfrog/s3/azure_blob
    % op.NetworkStoragePath = '<Artifactory network storage path>';
    % op.ArtifactoryUrl = '<JFrog artifactory url>';
    % op.ArtifactoryRepoName = '<JFrog artifactory repo name>';
    % op.S3BucketName = '<AWS S3 bucket name>';
    % op.S3AwsAccessKeyID = '<AWS S3 access key id>';
    op.AzContainerName = 'padvcontainer';
    op.RunnerType = "container";          % default/container
    op.ImageTag = 'slcicd.azurecr.io/slcheck/padv-ci:r2024b_apr25t_ci_spkg20250803';
    % op.ImageArgs = "<Docker container arguments>";
    
    % Docker image settings
    op.UseMatlabPlugin = false;
    op.MatlabLaunchCmd = "xvfb-run -a matlab-batch"; 
    op.MatlabStartupOptions = "";
    op.AddBatchStartupOption = false;
    padv.pipeline.generatePipeline(op, "CIPipeline");
end