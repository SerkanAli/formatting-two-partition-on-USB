//
//  ViewController.swift
//  USBTOOL
//
//  Created by MAC-IT-SERKAN on 18.11.16.
//  Copyright © 2016 MAC-ITSerkan. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {


    @IBOutlet weak var PushFormat: NSButton!
    @IBOutlet weak var ValueMacPartition: NSTextField!
    @IBOutlet weak var ValueWindowsPartition: NSTextField!
    @IBOutlet weak var SliderForPartition: NSSlider!
    @IBOutlet weak var TableView: NSTableView!
    @IBOutlet weak var NameWinPar: NSTextField!
    @IBOutlet weak var NameMacPar: NSTextField!
    @IBOutlet weak var Progress: NSProgressIndicator!
    @IBOutlet weak var ValueTextWin: NSTextField!
    @IBOutlet weak var ValueTextMac: NSTextField!
    var DiskName : String!
    var objects: NSMutableArray! = NSMutableArray()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        FilltheViewTable()
        ValueMacPartition.doubleValue = 50
        ValueWindowsPartition.doubleValue = 50
        SliderForPartition.doubleValue = 50
//        [Progress, setHidden:YES]
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = TableView.makeViewWithIdentifier("cell", owner: self) as! NSTableCellView
        cellView.textField!.stringValue = self.objects.objectAtIndex(row) as! String
        return cellView
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.objects.count
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        if( self.TableView.numberOfSelectedRows > 0)
        {
            let selectedItem = self.objects.objectAtIndex(self.TableView.selectedRow) as! String
            let index = selectedItem.rangeOfString("disk")
            DiskName = String(selectedItem[index!.endIndex])
            
           // self.TableView.deselectRow(self.TableView.selectedRow)
        }
    }
    
    func FilltheViewTable(){
        self.objects.removeAllObjects()
        if let session = DASessionCreate(kCFAllocatorDefault){
            let mountedVolumes = NSFileManager.defaultManager().mountedVolumeURLsIncludingResourceValuesForKeys([], options: [])!
            for volume in  mountedVolumes{
                if let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, volume){
                    if let bsdName = String.fromCString(DADiskGetBSDName(disk)){
                        let index = bsdName.rangeOfString("disk")
                        var bufString : String = volume.path! + "  disk" + String( bsdName[index!.endIndex])
                        bsdName.containsString(String(bsdName[index!.endIndex]))
                        let USBIndex = CheckifUSB(String(bsdName[index!.endIndex]))
                        if( USBIndex != -1){
                            let sizeOfMount =  CheckSizeUSB(USBIndex)
                            let sizeDouble = Double(Double(Int(sizeOfMount / 10000000))/100.0)
                            bufString += "                         "
                            bufString += "\(sizeDouble)"
                            bufString += " GB"
                            if( sizeDouble < 65.0){
                                self.objects.addObject(bufString)
                            }
                            
                        }
                    }
                }
            }
            self.TableView.reloadData()
        }

    }

    @IBAction func SliderValueChanged(sender: NSSlider) {
        let currentValue = sender.doubleValue
        ValueWindowsPartition.doubleValue = currentValue + sender.minValue
        ValueMacPartition.doubleValue = sender.maxValue - currentValue + sender.minValue
        if(DiskName != nil){
            let TotalGB = CheckSizeUSB((NSNumber(integer:Int(DiskName)!)))
            let calWTotal:Int = Int((ValueWindowsPartition.doubleValue * TotalGB / 100)/10000000)
            let calWin = Double((Double(calWTotal) / 100.0))
            ValueTextWin.stringValue = ""
            ValueTextWin.stringValue += "\(calWin)"
            ValueTextWin.stringValue += " GB"
            let calMTotal: Int = Int((ValueMacPartition.doubleValue * TotalGB / 100)/10000000)
            let calMac = Double((Double(calMTotal) / 100.0))
            ValueTextMac.stringValue = ""
            ValueTextMac.stringValue += "\(calMac)"
            ValueTextMac.stringValue += " GB"
        }
    }
   
    @IBAction func WindowsParValueChanged(sender: NSTextField) {
        let currentWinValue = sender.doubleValue
        SliderForPartition.doubleValue = currentWinValue
        ValueWindowsPartition.doubleValue = currentWinValue
        ValueMacPartition.doubleValue = 100 - currentWinValue
    }
    
    @IBAction func MacParValueChanged(sender: NSTextField) {
        
        let currentMacValue = sender.doubleValue
        SliderForPartition.doubleValue = 100 - currentMacValue
        ValueMacPartition.doubleValue =  currentMacValue
        ValueWindowsPartition.doubleValue = 100 - currentMacValue
    }
    
    @IBAction func PressFormatButton(sender: NSButton) {
        //Check if there is any selected Disk => errindex 0
        if (TableView.selectedRow < 0){
            ShowWarningMsg(0)
            return
            }
        
        // Check the name for the new Partition => errindex = 2
        let blank = ""
        if( NameMacPar.stringValue == NameWinPar.stringValue || NameWinPar.stringValue == blank || NameMacPar.stringValue == blank ){
            ShowWarningMsg(2)
            return
            }
        //Last warning before format, that all files will deleted
        if(ShowWarningMsg(4)){
            return
        }
        self.Progress.startAnimation(NSButton)
        let task = NSTask()
        let outputFormat = NSPipe()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["diskutil", "partitionDisk","/dev/disk" + DiskName,"MBRFormat","MS-DOS", NameWinPar.stringValue.uppercaseString, ValueWindowsPartition.stringValue + "%", "HFS+", NameMacPar.stringValue , ValueMacPartition.stringValue + "%"]
        task.standardOutput = outputFormat
        task.launch()
        task.waitUntilExit()
        let dataFormat = outputFormat.fileHandleForReading.readDataToEndOfFile()
        let outputString = String(dataFormat: dataFormat, encoding: NSUTF8StringEncoding)
        FilltheViewTable()
        ShowWarningMsg(3)
    }
    
    func CheckifUSB (index : String) -> NSNumber {
        //Check that the disk is a USB => errindex 1
        let taskProfiler = NSTask()
        let taskGrep = NSTask()
        let outputPipe = NSPipe()
        
        taskProfiler.launchPath = "/usr/sbin/system_profiler"
        taskGrep.launchPath = "/usr/bin/grep"
        
        taskProfiler.arguments = ["SPUSBDataType"]
        taskGrep.arguments = ["BSD Name"]
        
        taskProfiler.standardOutput = outputPipe
        taskGrep.standardInput = outputPipe
        
        let pipeMe = NSPipe()
        taskGrep.standardOutput = pipeMe
        
        let grepOutput = pipeMe.fileHandleForReading
        
        taskProfiler.launch()
        taskProfiler.waitUntilExit()
        taskGrep.launch()
        taskGrep.waitUntilExit()
        
        let data = grepOutput.readDataToEndOfFile()
        var output  = String(data: data, encoding: NSUTF8StringEncoding)
        let control = output?.rangeOfString("disk" + index)
        if(control == nil){
            return -1;
        }
        else{
            var index = 0
            var DiskRange = output?.rangeOfString("disk")
            if( DiskRange?.count == 0)
            {
                return -1
            }
            while( control?.first != DiskRange?.first  && DiskRange != nil){
                output?.replaceRange(DiskRange!, with: "MISK")
                DiskRange = output?.rangeOfString("disk")
                index++
            }
            return index;
        }
        
    }
    
    func CheckSizeUSB (index : NSNumber) -> Double {
        //Check that the disk is a USB => errindex 1
        let taskProfiler = NSTask()
        let taskGrep = NSTask()
        let outputPipe = NSPipe()
        
        taskProfiler.launchPath = "/usr/sbin/system_profiler"
        taskGrep.launchPath = "/usr/bin/grep"
        
        taskProfiler.arguments = ["SPUSBDataType"]
        taskGrep.arguments = ["Capacity"]
        
        taskProfiler.standardOutput = outputPipe
        taskGrep.standardInput = outputPipe
        
        let pipeMe = NSPipe()
        taskGrep.standardOutput = pipeMe
        
        let grepOutput = pipeMe.fileHandleForReading
        
        taskProfiler.launch()
        taskProfiler.waitUntilExit()
        taskGrep.launch()
        taskGrep.waitUntilExit()
        
        let data = grepOutput.readDataToEndOfFile()
        var output  = String(data: data, encoding: NSUTF8StringEncoding)
       
            var secondIndex = 0
            var DiskRange = output?.rangeOfString("Capacity")
            if( DiskRange?.count == 0){
                return 0;
            }
            while( secondIndex != index && DiskRange != nil){
                output?.replaceRange(DiskRange!, with: "MAPACITY")
                DiskRange = output?.rangeOfString("Capacity")
                secondIndex++
            }
            let BufString = output?.substringFromIndex((DiskRange?.last)!)
            var ByteRange = BufString?.rangeOfString("bytes")
        var newString = BufString?.substringToIndex((ByteRange?.first)!)
            ByteRange = newString?.rangeOfString("(")
        newString = (newString?.substringFromIndex((ByteRange?.first)!))!
        newString?.removeAtIndex((newString?.startIndex)!)
        newString = newString?.stringByReplacingOccurrencesOfString(".", withString: "")
        newString = (newString?.substringToIndex(newString!.endIndex.predecessor()))!
            return Double(newString!)!;
    }
    

    
    func ShowWarningMsg(errindex : Int)-> Bool {
        let myPopup: NSAlert = NSAlert()
        self.Progress.stopAnimation(NSButton)
        myPopup.messageText = "Some Error occured!"
        myPopup.alertStyle = NSAlertStyle.CriticalAlertStyle
        switch errindex{
        case 0:
            myPopup.informativeText = "There is no selected Disk"
        case 1:
            myPopup.informativeText = "The selected Disk is not a USB device. \nPlease select a USB device."
        case 2:
            myPopup.informativeText = "The Name for a Partition is empty or equel to each other."
        case 3:
            myPopup.messageText = "Task complete"
            myPopup.informativeText = "Formating the USB was succesfull"
            myPopup.alertStyle = NSAlertStyle.InformationalAlertStyle
        case 4:
            myPopup.addButtonWithTitle("Cancel")
            myPopup.messageText = "Are you sure to format the selected Disk?"
            myPopup.informativeText = "This Task will delete all Files on the selected disk, you should save your Data before pressing 'OK'."

        default:
            myPopup.informativeText = ""
            
        }
        myPopup.addButtonWithTitle("OK")
        let responseTag = myPopup.runModal()
        if (responseTag == NSAlertFirstButtonReturn){
            return true
        }
        else{
            return false
        }
    }
}

