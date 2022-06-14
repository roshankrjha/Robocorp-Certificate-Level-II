*** Settings ***
# Task Name: Order bots from RobotSpareBin
# Task Description : Bot will open RobotSpareBin order portal, open the order csv extract the details, place orders, save the confirmation, create pdf and zip the pdfs
# Developer Name: Roshan Jha
# Version: V.0.1
# Git Path:
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             OperatingSystem
Library             RPA.Browser.Selenium    auto_close=${True}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
# Variable Initialization
# ${order_Url}    https://robotsparebinindustries.com/#/robot-order
# ${order_Csv}    https://robotsparebinindustries.com/orders.csv

${image_Folder}     ${OUTPUT_DIR}${/}Image_Folder
${pdf_Folder}       ${OUTPUT_DIR}${/}Pdf_Folder
${output_Folder}    ${OUTPUT_DIR}${/}Output_Folder

${order_file}       ${output_Folder}${/}Orders.csv
${zip_file}         ${output_Folder}${/}PDF_Archive.zip


*** Tasks ***
# Master Task
Order Robots From RobotSpareBin Industries Inc
    # Call SubTasks
    Manage Folders
    # Get User Name
    ${credentials} =    Get Secret    credentials
    # Start Dialog
    LOG    ${credentials}
    Start Dialog    ${credentials}[username]
    # Get URLs from User
    ${urls} =    Collect Urls From User
    # Open Website
    Open RobotSpareBin Order Website    ${urls}[order-url]
    # Get Orders
    ${orders} =    Get Orders    ${urls}[order-csv]
    # Process each order from the orders
    FOR    ${row}    IN    @{orders}
        # Close the notification popup
        Close the annoying modal
        # Fill the order form
        Fill the form    ${row}
        # Priview The Robot
        Wait Until Keyword Succeeds    20    2s    Preview The Robot
        # Submit the order
        Wait Until Keyword Succeeds    20    2s    Submit the order
        # Create PDFs from the order receipt
        ${pdf} =    Store the receipt as a PDF file    ${row}[Order number]
        # Take bot screenshot
        ${screenshot} =    Take a screenshot of the robot    ${row}[Order number]
        # Add bot screenshot to the PDF
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        # Place the Next order
        Go to order another robot
    END
    # Create Zip File with all the PDFs
    Create a ZIP file of the receipts
    # Complete Dialog box
    Complete Dialog    ${credentials}[username]


*** Keywords ***
# Sub Task Defination
Manage Folders
    Create Directory    ${image_Folder}
    Create Directory    ${pdf_Folder}
    Create Directory    ${Output_Folder}

    Empty Directory    ${image_Folder}
    Empty Directory    ${pdf_Folder}
    Empty Directory    ${output_Folder}

collect Urls From User
    Add heading    User Input
    Add text input    order-url    Please Enter Order URL:
    Add text input    order-csv    Please Enter Order CSV URL:
    ${response} =    Run dialog
    RETURN    ${response}

Start Dialog
    [Arguments]    ${username}
    Add heading    "Started Processing"
    Add text    Hi ${username}, Your Task Started Processing.
    Run Dialog

Open RobotSpareBin Order Website
    [Arguments]    ${order_Url}
    Open Available Browser    ${order_Url}
    Maximize Browser Window

Get Orders
    [Arguments]    ${order_csv}
    Download    ${order_Csv}    ${order_File}    overwrite=True
    ${order_data} =    Read table from CSV    path=${order_File}    header=True
    RETURN    ${order_Data}

Close the annoying modal
    Click Button    class:btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://*[@class='form-control' and @type='number']    ${row}[Legs]
    Input Text    name:address    ${row}[Address]

Preview The Robot
    Click Button    id:preview
    Set Selenium Timeout    2s
    Wait Until Element Is Visible    id:robot-preview-image

Submit the Order
    Click Button    id:order
    Page Should Contain Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_no}
    Wait Until Element Is Visible    id:receipt
    ${order_receipt_html} =    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    ${pdf_Folder}${/}${order_no}.pdf
    RETURN    ${pdf_Folder}${/}${order_no}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_no}
    Wait Until Element Is Visible    id:robot-preview-image
    Set Selenium Timeout    1s
    Capture Element Screenshot    id:robot-preview-image    ${image_Folder}${/}${order_no}.png
    RETURN    ${image_Folder}${/}${order_no}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${image}    ${pdf}
    Open Pdf    ${pdf}
    ${files} =    Create List    ${image}:x=0,y=0
    Add Files To Pdf    ${files}    ${pdf}    ${True}

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${pdf_Folder}    ${zip_file}

Complete Dialog
    [Arguments]    ${username}
    Add heading    Completed Processing
    Add text    ${username}, Bot Completed Processing
    Run Dialog
