%% Su-Backstrom-William-Palecek (SuBaWiPa) Distress Detector
% This background program periodically captures a photo of the user and
% utilizes machine-learning to identify the emotional state of the user. It
% then determines if emotions are trending negatively and prompts the user
% to seek guidance according to their filed support system contact.

% This program requires a few MATLAB Add-Ons to operate: the MATLAB Support
% Package for USB Webcams, the Computer Vision Toolbox, the Image
% Processing Toolbox, and the Deep Learning Toolbox. This program also
% requries the 

% The SuBaWiPa Distress Detector was created in April 2021 for the BMEn
% 3415 Biomedical Systems Analysis Lab course at the University of
% Minnesota. Contributers include Matthew Su, Grace Backstrom, Mary
% William, and Alexander Palecek.

% This is a full-scale program designed to run as a background process.
% MATLAB should remain open at all times. If the computer is power cycled,
% the program should be restarted.

%% Initialization
try
    load returning_user_status.mat
    if returning_user == 1 %user has completed initialization previously, continue on to data
        %if user is new, returning_user is unrecognized, causing error and
        %leading to catch
    end
catch %returning_user is unrecognized variable and initialization is required
    
    % Run Initialization functions
    [TOS_status,demographics,support_method,support_contacts] = Initialize;
    
    returning_user = 1; %next time, the if statement at top will skip this catch and move on
    save returning_user_status.mat returning_user
end
%%

[processedImage,data] = datacollection(); %collect data

%need to be there or the API prints a picture. 
mood = {'Sad', 'Neutral', 'Fear', 'Anger', 'Disgust', 'Surprise', 'Happy'};
figure
hold on
yline(4);
plot(data,'-x');
set(gca,'ytick',(1:7),'yticklabel',mood)
hold off


%% Create a Report

import mlreportgen.report.* 
import mlreportgen.dom.* 
rpt = Report('Emotional Trends Report','pdf'); 

%title page
tp = TitlePage; 
tp.Title = 'Emotional Trends Report with Image Processing via Machine Learning'; 
tp.Author = {'Alexander Palecek, ';'Grace Backstrom, ';'Matthew Su, ';'Mary William'}; 
append(rpt,tp);

%create chapter01 
ch1 = Chapter('Emotional Trends Report'); 
sec1=Section('Plot of Data Generated form the Last 30 Days');
p1=Text(['Sadness, Neutral, Fear, and Anger moods are suggestive of a depressive disorder. ' ...
    'The graph below generates a trend that determines if an individual exhibits any symptoms of a depressive ' ...
    'disorder. We have set the line at anger to be the threshold. If an individual ' ...
    'mostly experiences these emotions, then we term that the individual shows depressive traits.  ']);
p2=Text(['Please be advised that this report is not intended to diagnose depressive disorders, but aims to ' ...
    'create trends that can be accessed by people of interest. ']);
P = (sum(data(:)<=4)/numel(data))*100;
if P>=50 
   p3 = Paragraph(sprintf('You have been showing depressive traits %d\n%%',round(P)));
else
   p3 = Paragraph(sprintf('You have not been showing depressive traits'));
end
% make the plot and put the image into the pdf
mood = {'Sad', 'Neutral', 'Fear', 'Anger', 'Disgust', 'Surprise', 'Happy'};
hold on
fig1 = Figure(plot(data,'-x'));
fig2 = Figure(yline(4));
hold off
set(gca,'ytick',(1:7),'yticklabel',mood)
title('Emotional Trends over the last 30 Days');
ylabel('Mood Detected by Image Processing');
xlabel('Time (Days)');

% Tie it in to the whole document
append(sec1,p1) ;
append(sec1,p2) ;
append(sec1,p3) ;
append(sec1,fig1) ;
append(ch1,sec1) ;
append(rpt,ch1);

%Close and run the report.
close(rpt)
rptview(rpt)

%% Local Functions

% Initialize
function [TOS_status,demographics,support_method,support_contacts] = Initialize()
[TOS_status] = chooseTOSdialog; %get terms of service agreement
[demographics] = get_demographics; % collect information about user demographics
[support_method] = get_support_method; % collect information about preferred user support method
[support_contacts] = get_support_contacts; % collect information about preferred user support contacts
end

% TOS
function TOS_status = chooseTOSdialog
terms = 'You agree to allow the SuBaWiPa Distress Detector to collect and store personal data such as facial images, personal identifying information, and contact information of your support structure. This data is confidential and only serves to monitor your wellbeing. Any shared data is anonymized and provided solely to medical professionals and data scientists whom agree to HIPAA standards.';
uiwait(msgbox(terms,'Terms of Services','modal'));

    d = dialog('Position',[300 300 250 150],'Name','Select One');
    txt = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[20 80 210 40],...
           'String','Do you agree to the terms of service?');
       
    popup = uicontrol('Parent',d,...
           'Style','popup',...
           'Position',[75 70 100 25],...
           'String',{'Yes';'No'},...
           'Callback',@popup_callback);
       
    btn = uicontrol('Parent',d,...
           'Position',[89 20 70 25],...
           'String','Close',...
           'Callback','delete(gcf)');
       
    TOS_status = 'Yes';
       
    % Wait for d to close before running to completion
    uiwait(d);
   
       function popup_callback(popup,event)
          idx = popup.Value;
          popup_items = popup.String;
          TOS_status = char(popup_items(idx,:));
       end
end

% Get_Demographics
function [demographics] = get_demographics()
demographics_categories = {'Spoken Language'; 'Country of Birth'; 'Racial/Ethnic Group'; 'Disability'; 'Gender'; 'Sexual Orientation'; 'Family Income'}; % 7 categories
spoken_languages = {'English'; 'Espanol'; '官话'; 'हिन्दी'; 'اَلْعَرَبِيَّةُ'; 'français'; 'Deutsch'; 'Россия'}; %english, spanish, mandarin chinese, hindi, arabic, french, german, russian
countries_birth = {'Afghanistan'; 'Albania'; 'Algeria'; 'Andorra'; 'Angola'; 'Antigua and Barbuda'; 'Argentina'; 'Armenia'; 'Australia'; 'Austria'; 'Azerbaijan'; 'Bahamas'; 'Bahrain'; 'Bangladesh'; 'Barbados'; ...
    'Belarus'; 'Belgium'; 'Belize'; 'Benin'; 'Bhutan'; 'Bolivia'; 'Bosnia and Herzegovina'; 'Botswana'; 'Brazil'; 'Brunei'; 'Bulgaria'; 'Burkina Faso'; 'Burundi'; 'Côte d Ivoire'; 'Cabo Verde'; ...
'Cambodia'; 'Cameroon'; 'Canada'; 'Central African Republic'; 'Chad'; 'Chile'; 'China'; 'Colombia'; 'Comoros'; 'Congo (Congo-Brazzaville)'; 'Costa Rica'; 'Croatia'; 'Cuba'; 'Cyprus'; 'Czechia (Czech Republic)'; ...
'Democratic Republic of the Congo'; 'Denmark'; 'Djibouti'; 'Dominica'; 'Dominican Republic'; 'Ecuador'; 'Egypt'; 'El Salvador'; 'Equatorial Guinea'; 'Eritrea'; 'Estonia'; 'Eswatini (fmr. "Swaziland")'; 'Ethiopia'; 'Fiji'; 'Finland'; ... 
'France'; 'Gabon'; 'Gambia'; 'Georgia'; 'Germany'; 'Ghana'; 'Greece'; 'Grenada'; 'Guatemala'; 'Guinea'; 'Guinea-Bissau'; 'Guyana'; 'Haiti'; 'Holy See'; 'Honduras'; ...
'Hungary'; 'Iceland'; 'India'; 'Indonesia'; 'Iran'; 'Iraq'; 'Ireland'; 'Israel'; 'Italy'; 'Jamaica'; 'Japan'; 'Jordan'; 'Kazakhstan'; 'Kenya'; 'Kiribati'; ...
'Kuwait'; 'Kyrgyzstan'; 'Laos'; 'Latvia'; 'Lebanon'; 'Lesotho'; 'Liberia'; 'Libya'; 'Liechtenstein'; 'Lithuania'; 'Luxembourg'; 'Madagascar'; 'Malawi'; 'Malaysia'; 'Maldives'; ...
'Mali'; 'Malta'; 'Marshall Islands'; 'Mauritania'; 'Mauritius'; 'Mexico'; 'Micronesia'; 'Moldova'; 'Monaco'; 'Mongolia'; 'Montenegro'; 'Morocco'; 'Mozambique'; 'Myanmar (formerly Burma)'; 'Namibia'; ...
'Nauru'; 'Nepal'; 'Netherlands'; 'New Zealand'; 'Nicaragua'; 'Niger'; 'Nigeria'; 'North Korea'; 'North Macedonia'; 'Norway'; 'Oman'; 'Pakistan'; 'Palau'; 'Palestine State'; 'Panama'; ...
'Papua New Guinea'; 'Paraguay'; 'Peru'; 'Philippines'; 'Poland'; 'Portugal'; 'Qatar'; 'Romania'; 'Russia'; 'Rwanda'; 'Saint Kitts and Nevis'; 'Saint Lucia'; 'Saint Vincent and the Grenadines'; 'Samoa'; 'San Marino'; ...
'Sao Tome and Principe'; 'Saudi Arabia'; 'Senegal'; 'Serbia'; 'Seychelles'; 'Sierra Leone'; 'Singapore'; 'Slovakia'; 'Slovenia'; 'Solomon Islands'; 'Somalia'; 'South Africa'; 'South Korea'; 'South Sudan'; 'Spain'; ...
'Sri Lanka'; 'Sudan'; 'Suriname'; 'Sweden'; 'Switzerland'; 'Syria'; 'Tajikistan'; 'Tanzania'; 'Thailand'; 'Timor-Leste'; 'Togo'; 'Tonga'; 'Trinidad and Tobago'; 'Tunisia'; 'Turkey'; ...
'Turkmenistan'; 'Tuvalu'; 'Uganda'; 'Ukraine'; 'United Arab Emirates'; 'United Kingdom'; 'United States of America'; 'Uruguay'; 'Uzbekistan'; 'Vanuatu'; 'Venezuela'; 'Vietnam'; 'Yemen'; 'Zambia'; 'Zimbabwe'};




end

% Get_Support_Method
function [support_method] = get_support_method()
end

% Get_Support_Contacts
function [support_contacts] = get_support_contacts()
end

% Data Collection
function [processedImage,data] = datacollection()
load('trainedNet.mat')
[snap] = takePicture(); %takes the picture
[processedImage,isImageUsable] = processPicture(snap); %process the snap
   if isImageUsable
    imshow(processedImage);
    pred = classify(trainedNet,processedImage); %happy, sad, angry, disgust, surprise, neutral, and fear
    %generate data for 
    if pred == "sad"
        data = 1;
    elseif pred == "neutral" 
        data = 2; 
    elseif pred == "fear"
        data = 3;
         elseif pred == "angry"
        data = 4; 
    elseif pred == "disgust"
        data = 5;
    elseif pred == "surprise"
        data = 6; 
    else
        data = 7;
    end
   end
end

% takePicture
function [snap] = takePicture()
% Needs toolbox: MATLAB Support Package for USB Webcams

% Inputs: 
% None.
% Outputs: 
% snap - The image taken by the camera.

cameraObj = webcam; % Create camera object/define what camera is being used.
pause(2) % Wait two seconds for camera to go online.
snap = snapshot(cameraObj); % Take picture.
clear cameraObj; % Turn off camera to disable any webcam lights/be as unobtrusive as possible.

end

% processPicture
function [processedImage,isImageUsable] = processPicture(snap)
% Needs toolbox: Computer Vision Toolbox

% Inputs: 
% snap - The image taken by the camera.
% Outputs: 
% processedImage - The cropped, grayscaled, 48x48 version of snap.
% isImageUsable - Boolean, returns 'true' if the image can be used in the
% neural net, or 'false' if the image is not suitable (face is angled to
% the side, the face is not detectable, etc.).

    try
        isImageUsable = true; % Set to true by default. Will test various things and adjust accordingly.

        faceDetector = vision.CascadeObjectDetector; % Set up face detector. By default, only detects upright/front-facing faces.
        bbox = faceDetector(snap); % Detect a face within the image.

        if size(bbox(1),1) == 1 % Make sure only 1 face is detected.
            cropped = imcrop(snap,bbox); % Crop the image.
            resized = imresize(cropped,[48 48]); % Resize the image, 128x128.
            processedImage = rgb2gray(resized); % Grayscale the image. Done processing.
        else % More or less than 1 faces are detected. That's a problem. 
            isImageUsable = false; 
        end    
    catch
        isImageUsable = false; % If any error is triggered, the image probably isn't usable. Could do some more robust tests, but that's a lot of work.
        processedImage = false; % Don't use the image!
    end

end