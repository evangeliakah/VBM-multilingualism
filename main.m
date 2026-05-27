% =========================================================
% person_a_VBM.m
% VBM Second-Level GLM + Brain Rendering
% Project: MNI Linguistic Study — Person A (Grey Matter)
% =========================================================
% INSTRUCTIONS:
%   1. Open MATLAB
%   2. Update paths in USER SETTINGS section below
%   3. Run (F5)
% =========================================================

clear all; close all; clc;

%% =========================================================
%  USER SETTINGS
% =========================================================

base_dir   = '/Users/evangeliakahremanis/Desktop/MNI-linguistic-study/data';
cat_dir    = fullfile(base_dir, 'derivatives', 'CAT26.0.rc3_3250');
smooth_dir = fullfile(base_dir, 'derivatives', 'smoothed_GM');
glm_dir    = fullfile(base_dir, 'derivatives', 'second_level_GLM');
csv_path   = '/Users/evangeliakahremanis/Desktop/MNI-linguistic-study/MNI-linguistic-study/shared_design_matrix.csv';
smooth_fwhm = 8;

%% =========================================================
%  SUBJECT LIST
% =========================================================

subs = {
    'sub-pp128', 'sub-pp145', 'sub-pp009', 'sub-pp006', 'sub-pp010', ...
    'sub-pp116', 'sub-pp021', 'sub-pp170', 'sub-pp099', 'sub-pp072', ...
    'sub-pp105', 'sub-pp171', 'sub-pp045', 'sub-pp020', 'sub-pp074', ...
    'sub-pp013', 'sub-pp035', 'sub-pp030', 'sub-pp033', 'sub-pp023', ...
    'sub-pp164', 'sub-pp042', 'sub-pp106', 'sub-pp092', 'sub-pp150', ...
    'sub-pp112', 'sub-pp025', 'sub-pp032', 'sub-pp155', 'sub-pp052', ...
    'sub-pp019', 'sub-pp162', 'sub-pp093', 'sub-pp048', 'sub-pp031', ...
    'sub-pp053', 'sub-pp110', 'sub-pp026', 'sub-pp129', 'sub-pp036', ...
    'sub-pp083', 'sub-pp027', 'sub-pp005', 'sub-pp091', 'sub-pp077', ...
    'sub-pp046', 'sub-pp012', 'sub-pp127', 'sub-pp044', 'sub-pp003', ...
    'sub-pp133'
};

%% =========================================================
%  STEP 1: Load design matrix
% =========================================================

fprintf('Loading design matrix...\n');
T = readtable(csv_path);
[~, idx] = ismember(subs, T.participant_id);

if any(idx == 0)
    missing = subs(idx == 0);
    error('These subjects not found in CSV: %s', strjoin(missing, ', '));
end

T51 = T(idx, :);
fprintf('Design matrix loaded: %d subjects, %d columns\n', height(T51), width(T51));

nlang_z   = T51.nlang_z;
entropy_z = T51.entropy_z;
age_z     = T51.age_z;
edu_z     = T51.edu_z;
sex       = T51.sex_binary;

%% =========================================================
%  STEP 2: Locate mwp1 GM files
% =========================================================

fprintf('\nLocating mwp1 GM files...\n');
mwp1_files = cell(length(subs), 1);

for i = 1:length(subs)
    sub      = subs{i};
    anat_dir = fullfile(cat_dir, sub, 'ses-01', 'anat');
    fname    = fullfile(anat_dir, ['mwp1' sub '_ses-01_rec-defaced_T1w.nii']);
    if ~exist(fname, 'file')
        error('Missing mwp1 file for %s', sub);
    end
    mwp1_files{i} = fname;
    fprintf('  Found: %s\n', sub);
end
fprintf('All 51 mwp1 files located.\n');

%% =========================================================
%  STEP 3: Smooth GM maps (8mm FWHM)
% =========================================================

fprintf('\nSmoothing GM maps with %dmm FWHM...\n', smooth_fwhm);
if ~exist(smooth_dir, 'dir'); mkdir(smooth_dir); end

smwp1_files = cell(length(subs), 1);

for i = 1:length(subs)
    sub = subs{i};
    [~, fname_noext] = fileparts(mwp1_files{i});
    out_fname = fullfile(smooth_dir, ['s' fname_noext '.nii']);
    smwp1_files{i} = out_fname;

    if exist(out_fname, 'file')
        fprintf('  Already smoothed, skipping: %s\n', sub);
        continue;
    end

    copyfile(mwp1_files{i}, fullfile(smooth_dir, [fname_noext '.nii']));
    matlabbatch_smooth{1}.spm.spatial.smooth.data  = {[fullfile(smooth_dir, [fname_noext '.nii']) ',1']};
    matlabbatch_smooth{1}.spm.spatial.smooth.fwhm  = [smooth_fwhm smooth_fwhm smooth_fwhm];
    matlabbatch_smooth{1}.spm.spatial.smooth.dtype = 0;
    matlabbatch_smooth{1}.spm.spatial.smooth.im    = 0;
    matlabbatch_smooth{1}.spm.spatial.smooth.prefix = 's';
    spm_jobman('run', matlabbatch_smooth);
    clear matlabbatch_smooth;
    fprintf('  Smoothed: %s\n', sub);
end
fprintf('Smoothing complete.\n');

%% =========================================================
%  STEP 4: Second-level GLM
% =========================================================

fprintf('\nSetting up second-level GLM...\n');
if ~exist(glm_dir, 'dir'); mkdir(glm_dir); end

scans = cell(length(subs), 1);
for i = 1:length(subs)
    [~, fname_noext] = fileparts(mwp1_files{i});
    scans{i} = [fullfile(smooth_dir, ['s' fname_noext '.nii']) ',1'];
end

matlabbatch{1}.spm.stats.factorial_design.dir                    = {glm_dir};
matlabbatch{1}.spm.stats.factorial_design.des.mreg.scans         = scans;
matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov          = struct([]);
matlabbatch{1}.spm.stats.factorial_design.des.mreg.incint        = 1;

matlabbatch{1}.spm.stats.factorial_design.cov(1).c     = nlang_z;
matlabbatch{1}.spm.stats.factorial_design.cov(1).cname = 'nlang_z';
matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFI  = 1;
matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC   = 1;

matlabbatch{1}.spm.stats.factorial_design.cov(2).c     = entropy_z;
matlabbatch{1}.spm.stats.factorial_design.cov(2).cname = 'entropy_z';
matlabbatch{1}.spm.stats.factorial_design.cov(2).iCFI  = 1;
matlabbatch{1}.spm.stats.factorial_design.cov(2).iCC   = 1;

matlabbatch{1}.spm.stats.factorial_design.cov(3).c     = age_z;
matlabbatch{1}.spm.stats.factorial_design.cov(3).cname = 'age_z';
matlabbatch{1}.spm.stats.factorial_design.cov(3).iCFI  = 1;
matlabbatch{1}.spm.stats.factorial_design.cov(3).iCC   = 1;

matlabbatch{1}.spm.stats.factorial_design.cov(4).c     = edu_z;
matlabbatch{1}.spm.stats.factorial_design.cov(4).cname = 'edu_z';
matlabbatch{1}.spm.stats.factorial_design.cov(4).iCFI  = 1;
matlabbatch{1}.spm.stats.factorial_design.cov(4).iCC   = 1;

matlabbatch{1}.spm.stats.factorial_design.cov(5).c     = sex;
matlabbatch{1}.spm.stats.factorial_design.cov(5).cname = 'sex_binary';
matlabbatch{1}.spm.stats.factorial_design.cov(5).iCFI  = 1;
matlabbatch{1}.spm.stats.factorial_design.cov(5).iCC   = 1;

matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none     = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im             = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em             = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit         = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm        = 1;

%% =========================================================
%  STEP 5: Estimate
% =========================================================

spm_mat = fullfile(glm_dir, 'SPM.mat');
matlabbatch{2}.spm.stats.fmri_est.spmmat           = {spm_mat};
matlabbatch{2}.spm.stats.fmri_est.write_residuals  = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

%% =========================================================
%  STEP 6: Contrasts
% =========================================================
% Column order: [intercept, nlang_z, entropy_z, age_z, edu_z, sex_binary]

matlabbatch{3}.spm.stats.con.spmmat = {spm_mat};

matlabbatch{3}.spm.stats.con.consess{1}.tcon.name    = 'nlang_z_positive';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.convec  = [0 1 0 0 0 0];
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.consess{2}.tcon.name    = 'nlang_z_negative';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.convec  = [0 -1 0 0 0 0];
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.consess{3}.tcon.name    = 'entropy_z_positive';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.convec  = [0 0 1 0 0 0];
matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.consess{4}.tcon.name    = 'entropy_z_negative';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.convec  = [0 0 -1 0 0 0];
matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.delete = 0;

%% =========================================================
%  RUN GLM PIPELINE
% =========================================================

fprintf('\nRunning GLM pipeline...\n');
spm('defaults', 'fmri');
spm_jobman('initcfg');
spm_jobman('run', matlabbatch);
fprintf('GLM complete.\n');

%% =========================================================
%  STEP 7: Brain rendering figures
% =========================================================

fprintf('\nGenerating brain rendering figures...\n');

contrasts = {'spmT_0001.nii','spmT_0002.nii','spmT_0003.nii','spmT_0004.nii'};
names     = {'nlang_z_positive','nlang_z_negative','entropy_z_positive','entropy_z_negative'};
template  = fullfile(spm('dir'),'canonical','single_subj_T1.nii');

Vt = spm_vol(template);
T1 = spm_read_vols(Vt);

for c = 1:4
    Vs   = spm_vol(fullfile(glm_dir, contrasts{c}));
    Tmap = zeros(Vt.dim);

    for zi = 1:Vt.dim(3)
        [xi,yi]  = ndgrid(1:Vt.dim(1), 1:Vt.dim(2));
        xyz_t    = [xi(:)'; yi(:)'; zi*ones(1,numel(xi)); ones(1,numel(xi))];
        xyz_s    = Vs.mat \ (Vt.mat * xyz_t);
        Tmap(:,:,zi) = reshape(spm_sample_vol(Vs, xyz_s(1,:), xyz_s(2,:), xyz_s(3,:), 1), Vt.dim(1), Vt.dim(2));
    end

    Tmap(Tmap < 3.28) = 0;

    [~, idx] = max(Tmap(:));
    [~,~,zpeak] = ind2sub(size(Tmap), idx);
    zpeak = max(4, min(zpeak, Vt.dim(3)-4));
    sl = [zpeak-3, zpeak, zpeak+3];

    figure('Color','k','Position',[100 100 900 300]);
    for i = 1:3
        subplot(1,3,i)
        img = T1(:,:,sl(i))';
        imagesc(img); colormap gray; axis image off; hold on
        tmp = Tmap(:,:,sl(i))';
        red = cat(3, ones(size(tmp)), zeros(size(tmp)), zeros(size(tmp)));
        h   = imagesc(red);
        set(h, 'AlphaData', tmp > 0);
        title(sprintf('z=%d', sl(i)), 'Color','w', 'FontSize',8);
        hold off
    end
    sgtitle(strrep(names{c},'_',' '), 'Color','w');
    print('-dpdf','-bestfit', fullfile(glm_dir, [names{c} '_brain.pdf']));
    fprintf('Saved: %s\n', names{c});
end

fprintf('\n=========================================================\n');
fprintf('ALL DONE!\n');
fprintf('Results saved to: %s\n', glm_dir);
fprintf('=========================================================\n');
