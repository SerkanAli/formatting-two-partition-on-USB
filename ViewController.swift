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

       
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = TableView.make(withIdentifier: "cell", owner: self) as! NSTableCellView
        cellView.textField!.stringValue = self.objects.object(at: row) as! String
        return cellView
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.objects.count
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if( self.TableView.numberOfSelectedRows > 0)
        {
            let selectedItem = self.objects.object(at: self.TableView.selectedRow) as! String
            let index = selectedItem.range(of: "disk")
            DiskName = String(selectedItem[index!.upperBound])
            
           // self.TableView.deselectRow(self.TableView.selectedRow)
        }
    }
    
    func FilltheViewTable(){
        let taskProfiler = Process()
        let taskGrep = Process()
        let outputPipe = Pipe()
        
        taskProfiler.launchPath = "/usr/sbin/system_profiler"
        taskGrep.launchPath = "/usr/bin/grep"
        
        taskProfiler.arguments = ["SPUSBDataType"]
        taskGrep.arguments = ["BSD Name"]
        
        taskProfiler.standardOutput = outputPipe
        taskGrep.standardInput = outputPipe
        
        let pipeMe = Pipe()
        taskGrep.standardOutput = pipeMe
        
        let grepOutput = pipeMe.fileHandleForReading
        
        taskProfiler.launch()
        taskProfiler.waitUntilExit()
        taskGrep.launch()
        taskGrep.waitUntilExit()
        
        let data = grepOutput.readDataToEndOfFile()
        var DiskIDs = [Character]()
        var output  = String(data: data, encoding: String.Encoding.utf8)
        var countIndex = 0
        var USBIndex = (output?.range(of: "disk"))
        if( USBIndex?.isEmpty )!
        {
            return
        }
        while( USBIndex != nil){
            let sizeOfMount =  CheckSizeUSB(NSNumber(value:Int(countIndex)))
            let sizeDouble = Double(Double(Int(sizeOfMount / 10000000))/100.0)
            var bufString : String = "disk"
            bufString += "\(output![USBIndex!.upperBound])"
            bufString += "             "
            bufString += "\(sizeDouble)"
            bufString += " GB"
            if( sizeDouble > 0.5 && sizeDouble < 65.0){
                if(!(DiskIDs.contains(output![USBIndex!.upperBound])))
                {
                    DiskIDs.append(output![USBIndex!.upperBound])
                    self.objects.add(bufString)
                }
            }
            output?.replaceSubrange(USBIndex!, with: "MISK")
            USBIndex = output?.range(of: "disk")
            countIndex += 1
        }
    }

    @IBAction func SliderValueChanged(_ sender: NSSlider) {
        let currentValue = sender.doubleValue
        ValueWindowsPartition.doubleValue = currentValue + sender.minValue
        ValueMacPartition.doubleValue = sender.maxValue - currentValue + sender.minValue
        if(DiskName != nil){
            let TotalGB = CheckSizeUSB(CheckifUSB(DiskName))
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
   
    @IBAction func WindowsParValueChanged(_ sender: NSTextField) {
        let currentWinValue = sender.doubleValue
        SliderForPartition.doubleValue = currentWinValue
        ValueWindowsPartition.doubleValue = currentWinValue
        ValueMacPartition.doubleValue = 100 - currentWinValue
    }
    
    @IBAction func MacParValueChanged(_ sender: NSTextField) {
        
        let currentMacValue = sender.doubleValue
        SliderForPartition.doubleValue = 100 - currentMacValue
        ValueMacPartition.doubleValue =  currentMacValue
        ValueWindowsPartition.doubleValue = 100 - currentMacValue
    }
    
    @IBAction func PressFormatButton(_ sender: NSButton) {
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
        print(DiskName)
        print(NameWinPar.stringValue.uppercased())
        print(ValueWindowsPartition.stringValue)
        self.Progress.startAnimation(NSButton)
        let task = Process()
        let outputFormat = Pipe()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["diskutil", "partitionDisk","/dev/disk" + DiskName,"MBRFormat","MS-DOS", NameWinPar.stringValue.uppercased(), ValueWindowsPartition.stringValue + "%", "HFS+", NameMacPar.stringValue , ValueMacPartition.stringValue + "%"]
        task.standardOutput = outputFormat
        task.launch()
        task.waitUntilExit()
       // let dataFormat = outputFormat.fileHandleForReading.readDataToEndOfFile()
       // let outputString = String(data: dataFormat, encoding: String.Encoding.utf8)
        FilltheViewTable()
        ShowWarningMsg(3)
    }
    
    func CheckifUSB (_ index : String) -> NSNumber {
        //Check that the disk is a USB => errindex 1
        let taskProfiler = Process()
        let taskGrep = Process()
        let outputPipe = Pipe()
        
        taskProfiler.launchPath = "/usr/sbin/system_profiler"
        taskGrep.launchPath = "/usr/bin/grep"
        
        taskProfiler.arguments = ["SPUSBDataType"]
        taskGrep.arguments = ["BSD Name"]
        
        taskProfiler.standardOutput = outputPipe
        taskGrep.standardInput = outputPipe
        
        let pipeMe = Pipe()
        taskGrep.standardOutput = pipeMe
        
        let grepOutput = pipeMe.fileHandleForReading
        
        taskProfiler.launch()
        taskProfiler.waitUntilExit()
        taskGrep.launch()
        taskGrep.waitUntilExit()
        
        let data = grepOutput.readDataToEndOfFile()
        var output  = String(data: data, encoding: String.Encoding.utf8)
        let control = output?.range(of: "disk" + index)
        if(control == nil){
            return -1;
        }
        else{
            var index = 0
            var DiskRange = (output?.range(of: "disk"))
            if( DiskRange?.isEmpty )!
            {
                return -1
            }
            while( control?.lowerBound != DiskRange?.lowerBound  && DiskRange != nil){
                output?.replaceSubrange(DiskRange!, with: "MISK")
                DiskRange = output?.range(of: "disk")
                index += 1
            }
            return NSNumber(value:Int(index));
        }
        
    }
    
    func CheckSizeUSB (_ index : NSNumber) -> Double {
        //Check that the disk is a USB => errindex 1
        let taskProfiler = Process()
        let taskGrep = Process()
        let outputPipe = Pipe()
        
        taskProfiler.launchPath = "/usr/sbin/system_profiler"
        taskGrep.launchPath = "/usr/bin/grep"
        
        taskProfiler.arguments = ["SPUSBDataType"]
        taskGrep.arguments = ["Capacity"]
        
        taskProfiler.standardOutput = outputPipe
        taskGrep.standardInput = outputPipe
        
        let pipeMe = Pipe()
        taskGrep.standardOutput = pipeMe
        
        let grepOutput = pipeMe.fileHandleForReading
        
        taskProfiler.launch()
        taskProfiler.waitUntilExit()
        taskGrep.launch()
        taskGrep.waitUntilExit()
        
        let data = grepOutput.readDataToEndOfFile()
        var output  = String(data: data, encoding: String.Encoding.utf8)
        var secondIndex = 0
        var DiskRange = output?.range(of: "Capacity")
        if( DiskRange?.isEmpty)!{
            return 0;
        }
        while( NSNumber(value:secondIndex) != index && DiskRange != nil){
                output?.replaceSubrange(DiskRange!, with: "MAPACITY")
                DiskRange = output?.range(of: "Capacity")
                secondIndex += 1
            }
            let BufString = output?.substring(from: (DiskRange?.upperBound)!)
            var ByteRange = BufString?.range(of: "bytes")
        var newString = BufString?.substring(to: (ByteRange?.lowerBound)!)
            ByteRange = newString?.range(of: "(")
        newString = (newString?.substring(from: (ByteRange?.lowerBound)!))!
        newString?.remove(at: (newString?.startIndex)!)
        newString = newString?.replacingOccurrences(of: ".", with: "")
        newString = (newString?.substring(to: newString!.characters.index(before: newString!.endIndex)))!
            return Double(newString!)!;
    }
    

    
    func ShowWarningMsg(_ errindex : Int)-> Bool {
        let myPopup: NSAlert = NSAlert()
        self.Progress.stopAnimation(NSButton)
        myPopup.messageText = "Some Error occured!"
        myPopup.alertStyle = NSAlertStyle.critical
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
            myPopup.alertStyle = NSAlertStyle.informational
        case 4:
            myPopup.addButton(withTitle: "Cancel")
            myPopup.messageText = "Are you sure to format the selected Disk?"
            myPopup.informativeText = "This Task will delete all Files on the selected disk, you should save your Data before pressing 'OK'."

        default:
            myPopup.informativeText = ""
            
        }
        myPopup.addButton(withTitle: "OK")
        let responseTag = myPopup.runModal()
        if (responseTag == NSAlertFirstButtonReturn){
            return true
        }
        else{
            return false
        }
    }
}


func GetDiskNumber(value: String) -> String {
    // Find index of space.
    let c = value.characters
    if let space = c.index(of: "k") {
        // Return substring.
        // ... Use "after" to avoid including the space in the substring.
        return value[c.index(after: space)..<value.endIndex]
    }
    return ""
}
