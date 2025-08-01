function processmodel(pm)
    % Defines the project's processmodel

    arguments
        pm padv.ProcessModel
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Include/Exclude Tasks in processmodel
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

    includeModelMaintainabilityMetricTask = true;
    includeModelTestingMetricTask = false;
    includeModelStandardsTask = false;
    includeDesignErrorDetectionTask = false;        % Disabled
    includeFindClones = false;
    includeModelComparisonTask = false;
    includeSDDTask = false;                         % Disabled
    includeSimulinkWebViewTask = true;
    includeTestsPerTestCaseTask = false;
    includeMergeTestResultsTask = false;
    includeRefGenerateCodeTask = false;
    includeTopGenerateCodeTask = false; % Project Level Top-Model code generation
    % Not supported in mpm / docker images
    includeRefAnalyzeModelCode = false && ~padv.internal.util.isMACA64 && exist('polyspaceroot','file');
    includeTopAnalyzeModelCode = false && ~padv.internal.util.isMACA64 && exist('polyspaceroot','file'); % Project Level Top-Model code analysis
    includeRefProveCodeQuality = false && ~padv.internal.util.isMACA64 && (~isempty(ver('pscodeprover')) || ~isempty(ver('pscodeproverserver')));
    includeTopProveCodeQuality = false && ~padv.internal.util.isMACA64 && (~isempty(ver('pscodeprover')) || ~isempty(ver('pscodeproverserver')));% Project Level Top-Model code proving
    includeRefCodeInspection = false;
    includeTopCodeInspection = false;
    includeGenerateRequirementsReport = true;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Define Shared Path Variables
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Set default root directory for task results
    pm.DefaultOutputDirectory = fullfile('$PROJECTROOT$', 'PA_Results');
    defaultResultPath = fullfile('$DEFAULTOUTPUTDIR$','$ITERATIONARTIFACT$');
    defaultTestResultPath = fullfile(defaultResultPath,'test_results');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Define Shared Queries
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    findModels = padv.builtin.query.FindModels(Name="ModelsQuery");
    findSlModels = padv.builtin.query.FindArtifacts(ArtifactType="sl_model_file");
    findModelsWithTests = padv.builtin.query.FindModelsWithTestCases(Parent=findModels);
    findTestsForModel = padv.builtin.query.FindTestCasesForModel(Parent=findModels);
    findRefModels = padv.builtin.query.FindRefModels(Name="RefModelsQuery");
    findTopModels = padv.builtin.query.FindTopModels(Name="TopModelsQuery");
    findProjectFile = padv.builtin.query.FindProjectFile();

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% P2
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    findRefModels2 = padv.builtin.query.FindRefModels(Name="RefModelsQuery");
    p2 = pm.addProcess("Process2");
    p2task2 = p2.addTask(padv.builtin.task.RunModelStandards(Name = "task2", IterationQuery=findRefModels2)); 
    p2task2.Title= "Task2-title";

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% P3
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    p2 = pm.addProcess("Process3");
    p2task2 = p2.addTask(padv.builtin.task.RunModelStandards(Name = "task3", IterationQuery=findRefModels2)); 
    p2task2.Title= "Task3-title";

    % 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Register Tasks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Collect Model Maintainability Metrics
    % Tools required: Simulink Check
    if includeModelMaintainabilityMetricTask
        mmMetricTask = pm.addTask(padv.builtin.task.CollectMetrics());
    end

    %% Check modeling standards
    % Tools required: Model Advisor
    if includeModelStandardsTask
        maTask = pm.addTask(padv.builtin.task.RunModelStandards(IterationQuery=findModels));
        maTask.addInputQueries(padv.builtin.query.FindFileWithAddress( ...
            Type='ma_config_file', Path=fullfile('tools','sampleChecks.json')));
        maTask.ReportPath = fullfile( ...
            defaultResultPath,'model_standards_results');
    end

    %% Detect design errors
    % Tools required: Simulink Design Verifier
    if includeDesignErrorDetectionTask
        dedTask = pm.addTask(padv.builtin.task.DetectDesignErrors(IterationQuery=findModels)); %#ok<*UNRCH>
        dedTask.ReportFilePath = fullfile( ...
            defaultResultPath, 'design_error_detections','$ITERATIONARTIFACT$_DED');
    end

    %% Generate clone detection reports
    % Tools required: Clone Detector
    if includeFindClones
        %Across Model Clones Instance
        acrossModelCloneDetectTask = pm.addTask(padv.builtin.task.FindClones(Name = "FindAcrossModelClones", ...
            IterationQuery=findModels,Title=message('padv_spkg:builtin_text:FindClonesAcrossModelTitle').getString()));
        acrossModelCloneDetectTask.ReportPath = fullfile(defaultResultPath,'findAcrossModelClones');
        acrossModelCloneDetectTask.AcrossModelReportName = "$ITERATIONARTIFACT$_AcrossModelClonesReport";
        acrossModelCloneDetectTask.DetectLibraryClones = false;
        %Library Clones Instance
        libCloneDetectTask = pm.addTask(padv.builtin.task.FindClones(Name = "FindLibraryClones", ...
            IterationQuery=findModels,Title=message('padv_spkg:builtin_text:FindLibraryClonesTitle').getString()));
        libCloneDetectTask.ReportPath = fullfile(defaultResultPath,'findLibraryClones');
        libCloneDetectTask.LibraryReportName = "$ITERATIONARTIFACT$_LibraryClonesReport";
        libCloneDetectTask.DetectClonesAcrossModel = false;
    end

    %% Generate Model Comparison
    if includeModelComparisonTask
        mdlCompTask = pm.addTask(padv.builtin.task.GenerateModelComparison(IterationQuery=findModels));
        mdlCompTask.ReportPath = fullfile( ...
            defaultResultPath,'model_comparison');
    end

    %% Generate SDD report (System Design Description)
    %  Tools required: Simulink Report Generator
    if includeSDDTask
        sddTask = pm.addTask(padv.builtin.task.GenerateSDDReport(IterationQuery=findModels));
        sddTask.ReportPath = fullfile( ...
            defaultResultPath,'system_design_description');
        sddTask.ReportName = '$ITERATIONARTIFACT$_SDD';
    end

    %% Generate Simulink web view
    % Tools required: Simulink Report Generator
    if includeSimulinkWebViewTask
        slwebTask = pm.addTask(padv.builtin.task.GenerateSimulinkWebView(IterationQuery=findModels));
        % slwebTask.ReportPath = fullfile(defaultResultPath,'webview');
        slwebTask.ReportPath = fullfile('$PROJECTROOT$/../../../level1-b', '04_Results', '$ITERATIONARTIFACT$', 'webview');
        slwebTask.ReportName = '$ITERATIONARTIFACT$_webview';
    end

    %% Run tests per test case
    % Tools required: Simulink Test
    if includeTestsPerTestCaseTask
        milTask = pm.addTask(padv.builtin.task.RunTestsPerTestCase(IterationQuery=findTestsForModel));
        % Configure the tests per testcase task
        milTask.OutputDirectory = defaultTestResultPath;
    end

    %% Merge test results
    % Tools required: Simulink Test (and optionally Simulink Coverage)
    if includeTestsPerTestCaseTask && includeMergeTestResultsTask
        mergeTestTask = pm.addTask(padv.builtin.task.MergeTestResults(IterationQuery=findModelsWithTests, PredecessorTask=milTask));
        mergeTestTask.ReportPath = defaultTestResultPath;
    end
	
    %% Collect Model Testing Metrics
    if includeModelTestingMetricTask
        mtMetricTask = pm.addTask(padv.builtin.task.CollectMetrics(Name="ModelTestingMetrics", IterationQuery=padv.builtin.query.FindUnits));
        mtMetricTask.Title = message('padv_spkg:builtin_text:ModelTestingMetricDemoTaskTitle').getString();
        mtMetricTask.Dashboard = "ModelUnitTesting";
        mtMetricTask.ReportName = "$ITERATIONARTIFACT$_ModelTesting";
        mtMetricTask.ReportPath = fullfile(defaultResultPath, 'testing_metrics');
    end	

    %% Generate Code
    % Tools required: Embedded Coder
    % By default, we generate code for all models in the project;
    if includeRefGenerateCodeTask
        codegenTask = pm.addTask(padv.builtin.task.GenerateCode("IterationQuery", ...
            findRefModels));
        codegenTask.UpdateThisModelReferenceTarget = 'IfOutOfDate';
        codegenTask.TreatAsRefModel = true;
        codegenTask.Title = "Reference Model Code Generation";
        codegenTask.GenerateExternalCodeCache = true;
        codegenTask.ExternalCodeCacheDirectory = fullfile(defaultResultPath, 'external_code_cache');
    end

    if includeTopGenerateCodeTask && includeRefGenerateCodeTask
        codegenTopTask = pm.addTask(padv.builtin.task.GenerateCode("IterationQuery", ...
            findProjectFile,"InputQueries",{findTopModels,...
            padv.builtin.query.GetOutputsOfDependentTask("padv.builtin.task.GenerateCode")},...
            "Name", "Top Model Code Generation"));
        codegenTopTask.UpdateThisModelReferenceTarget = 'IfOutOfDate';
        codegenTopTask.TreatAsRefModel = false;
        codegenTopTask.Title = "Top Model Code Generation";
        codegenTopTask.TrackAllGeneratedCode = true;
    end

    %% Check coding standards 
    % Tools required: Polyspace Bug Finder
    if includeRefGenerateCodeTask && includeRefAnalyzeModelCode
        psbfTask = pm.addTask(padv.builtin.task.AnalyzeModelCode("IterationQuery", ...
            findRefModels,"Name","Reference Model Code Analysis"));
        psbfTask.ResultDir = fullfile(defaultResultPath,'bug_finder');
        psbfTask.ReportPath = fullfile(defaultResultPath,'bug_finder');
        psbfTask.Title = "Reference Model Code Analysis";
    end

    if includeTopGenerateCodeTask && includeTopAnalyzeModelCode
        psbfTopTask = pm.addTask(padv.builtin.task.AnalyzeModelCode("IterationQuery", ...
            findProjectFile,"InputQueries",...
            {padv.builtin.query.GetOutputsOfDependentTask("Top Model Code Generation"),...
            findTopModels},...
            "Name","Top Model Code Analysis"));

        psbfTopTask.PsPrjFileName = "$INPUTARTIFACT$_BugFinder";
        psbfTopTask.Title = "Top Model Code Analysis";
        psbfTopTask.ResultDir = fullfile('$DEFAULTOUTPUTDIR$', 'bug_finder', '$INPUTARTIFACT$');
        psbfTopTask.ReportPath = string(fullfile('$DEFAULTOUTPUTDIR$', 'bug_finder', '$INPUTARTIFACT$'));
        psbfTopTask.ReportNames = ["$INPUTARTIFACT$_BugFinderSummary", ...
            "$INPUTARTIFACT$_CodingStandards"];
        psbfTopTask.OutputDirectory = string(fullfile('$DEFAULTOUTPUTDIR$', 'bug_finder'));
    end

    %% Prove Code Quality
    % Tools required: Polyspace Code Prover
    if includeRefGenerateCodeTask && includeRefProveCodeQuality
        pscpTask = pm.addTask(padv.builtin.task.AnalyzeModelCode(Name="RefProveCodeQuality", IterationQuery= ...
            findRefModels));
        pscpTask.Title = "Ref Model Code Proving";
        pscpTask.VerificationMode = "CodeProver";
        pscpTask.ResultDir = string(fullfile(defaultResultPath,'code_prover'));
        pscpTask.Reports = ["Developer", "CallHierarchy", "VariableAccess"];
        pscpTask.ReportPath = string(fullfile(defaultResultPath,'code_prover'));
        pscpTask.ReportNames = [...
            "$ITERATIONARTIFACT$_Developer", ...
            "$ITERATIONARTIFACT$_CallHierarchy", ...
            "$ITERATIONARTIFACT$_VariableAccess"];
    end

    if includeTopGenerateCodeTask && includeTopProveCodeQuality
        pscpTopTask = pm.addTask(padv.builtin.task.AnalyzeModelCode(Name="TopProveCodeQuality", IterationQuery= ...
            findProjectFile, ...
            InputQueries={padv.builtin.query.GetOutputsOfDependentTask("Top Model Code Generation"),...
            findTopModels}));
        pscpTopTask.Title = "Top Model Code Proving";
        pscpTopTask.VerificationMode = "CodeProver";
        pscpTopTask.ResultDir = string(fullfile('$DEFAULTOUTPUTDIR$', 'code_prover', '$INPUTARTIFACT$'));
        pscpTopTask.Reports = ["Developer", "CallHierarchy", "VariableAccess"];
        pscpTopTask.ReportPath = string(fullfile('$DEFAULTOUTPUTDIR$', 'code_prover', '$INPUTARTIFACT$'));
        pscpTopTask.ReportNames = [...
            "$INPUTARTIFACT$_Developer", ...
            "$INPUTARTIFACT$_CallHierarchy", ...
            "$INPUTARTIFACT$_VariableAccess"];
        pscpTopTask.OutputDirectory = string(fullfile('$DEFAULTOUTPUTDIR$', 'code_prover'));
    end

    %% Inspect Reference Model Code
    if includeRefGenerateCodeTask && includeRefCodeInspection
        slciTask = pm.addTask(padv.builtin.task.RunCodeInspection("IterationQuery", ...
            findRefModels));
        slciTask.ReportFolder = fullfile(defaultResultPath,'code_inspection');
        slciTask.Title = "Ref Model Code Inspection";
    end

    if includeTopGenerateCodeTask && includeTopCodeInspection
        slciTopTask = pm.addTask(padv.builtin.task.RunCodeInspection("IterationQuery", ...
            findProjectFile,"InputQueries",...
            {padv.builtin.query.GetOutputsOfDependentTask("Top Model Code Generation"),...
            findTopModels},"Name","Top Model Code Inspection"));
        slciTopTask.Title = "Top Model Code Inspection";
        slciTopTask.ReportFolder = fullfile('$DEFAULTOUTPUTDIR$','code_inspection', '$INPUTARTIFACT$');
        slciTopTask.OutputDirectory = string(fullfile('$DEFAULTOUTPUTDIR$', 'code_inspection'));
    end

    %% Generate Requirements report
    % Tools required: Requirements Toolbox
    if includeGenerateRequirementsReport
        rqmtTask = pm.addTask(padv.builtin.task.GenerateRequirementsReport()); %#ok<NASGU>
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Set Task relationships
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Set Task Dependencies
    if includeRefGenerateCodeTask && includeRefCodeInspection
        slciTask.dependsOn(codegenTask);
    end
    if includeRefGenerateCodeTask && includeRefAnalyzeModelCode
        psbfTask.dependsOn(codegenTask);
    end
    if includeRefGenerateCodeTask && includeRefProveCodeQuality
        pscpTask.dependsOn(codegenTask);
    end

    if includeRefGenerateCodeTask && includeTopGenerateCodeTask
        codegenTopTask.dependsOn(codegenTask);
    end
    if includeTopGenerateCodeTask && includeTopCodeInspection && ...
            includeRefGenerateCodeTask
        slciTopTask.dependsOn(codegenTopTask);
    end
    if includeTopGenerateCodeTask && includeTopAnalyzeModelCode && ...
            includeRefGenerateCodeTask
        psbfTopTask.dependsOn(codegenTopTask);
    end
    if includeTopGenerateCodeTask && includeTopProveCodeQuality && ...
            includeRefGenerateCodeTask
        pscpTopTask.dependsOn(codegenTopTask);
    end

    if includeTestsPerTestCaseTask && includeMergeTestResultsTask
        mergeTestTask.dependsOn(milTask, "WhenStatus",{'Pass','Fail'});
    end

    %% Set Task Run-Order
    if includeMergeTestResultsTask && includeModelTestingMetricTask
        mtMetricTask.runsAfter(mergeTestTask);
    end
    if includeSimulinkWebViewTask && includeModelMaintainabilityMetricTask
        slwebTask.runsAfter(mmMetricTask);
    end
    if includeModelStandardsTask && includeModelMaintainabilityMetricTask
        maTask.runsAfter(mmMetricTask);
    end
    if includeModelStandardsTask && includeSimulinkWebViewTask
        maTask.runsAfter(slwebTask);
    end
    if includeModelStandardsTask && includeFindClones
        acrossModelCloneDetectTask.runsAfter(maTask);
        libCloneDetectTask.runsAfter(maTask);
    end
    if includeDesignErrorDetectionTask && includeModelStandardsTask
        dedTask.runsAfter(maTask); %#ok<*NODEF>
    end
    if includeModelComparisonTask && includeModelStandardsTask
        mdlCompTask.runsAfter(maTask);
    end
    if includeSDDTask && includeModelStandardsTask
        sddTask.runsAfter(maTask);
    end
    if includeTestsPerTestCaseTask && includeModelStandardsTask
        milTask.runsAfter(maTask);
    end
    if includeRefGenerateCodeTask && includeRefAnalyzeModelCode && includeRefProveCodeQuality
        pscpTask.runsAfter(psbfTask);
    end
    % Set the code generation task to always run after Model Standards,
    % System Design Description and Test tasks
    if includeRefGenerateCodeTask && includeModelStandardsTask
        codegenTask.runsAfter(maTask);
    end
    if includeRefGenerateCodeTask && includeFindClones
        codegenTask.runsAfter(acrossModelCloneDetectTask);
        codegenTask.runsAfter(libCloneDetectTask);
    end
    if includeRefGenerateCodeTask && includeSDDTask
        codegenTask.runsAfter(sddTask);
    end
    if includeRefGenerateCodeTask && includeTestsPerTestCaseTask
        codegenTask.runsAfter(milTask);
    end
    if includeRefGenerateCodeTask && includeModelTestingMetricTask
        codegenTask.runsAfter(mtMetricTask);
    end	
    % Both the Polyspace Bug Finder (PSBF) and the Simulink Code Inspector
    % (SLCI) tasks depend on the code generation tasks. SLCI task is set to
    % run after the PSBF task without establishing an execution dependency
    % by using 'runsAfter'.
    if includeRefGenerateCodeTask && includeRefAnalyzeModelCode ...
            && includeRefCodeInspection
        slciTask.runsAfter(pscpTask);
    end

    if includeRefGenerateCodeTask && includeTopGenerateCodeTask ...
            && includeRefCodeInspection
        codegenTopTask.runsAfter(slciTask);
    end

    if includeRefGenerateCodeTask && includeTopGenerateCodeTask ...
            && includeRefAnalyzeModelCode
        codegenTopTask.runsAfter(psbfTask);
    end

    if includeRefGenerateCodeTask && includeTopGenerateCodeTask ...
            && includeRefProveCodeQuality
        codegenTopTask.runsAfter(pscpTask);
    end

    if includeRefGenerateCodeTask && includeTopGenerateCodeTask && ...
            includeTopProveCodeQuality && includeTopAnalyzeModelCode
        pscpTopTask.runsAfter(psbfTopTask);
    end

    if includeRefGenerateCodeTask && includeTopGenerateCodeTask && ...
            includeRefCodeInspection && includeTopProveCodeQuality
        slciTopTask.runsAfter(pscpTopTask);
    end

    % !PROCESSMODEL_EDITOR_MARKER! %
    % Do not remove. Process Advisor uses the comment above to automatically add tasks. %

end