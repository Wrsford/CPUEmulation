// JS implementation of MinimalCPU
function MinimalCPU() {
    var self = this;
    
    self.programCounter = 0x0;
    self.dataRegister = 0x0;
    self.backupRegister = 0x0;
    
    self.stack = [];
    self.callstack = [];
    self.interruptTable = {};
    self.breakFlag = 0x0;
    // console.log prints the whole line :/ cache the output until a newline
    self.printCache = "";
    
    // Reliance on more than one JS file is not something I like.
    var shouldContinueWithoutRAM = false;
    // Check for other MinimalRAM's existance
    if (typeof(MinimalRAM) === typeof(undefined))
    {
        // Doesn't exist :/
        console.warn("MinimalRAM not found.");
        if (shouldContinueWithoutRAM)
        {
            console.warn("Will continue with limited capabilities, but functions will not work!");
            self.ram = null;
        }
        else
        {
            console.error("Cannot continue without MinimalRAM!");
            return null;
        }
    }
    else
    {
        // It exists
        self.ram = new MinimalRAM();
    }
    
    
    var push = function(val)
    {
        self.stack.push(val);
    }
    self.push = push;
    
    var pop = function()
    {
        return self.stack.pop();
    }
    self.pop = pop;
    
    var sub = function()
    {
        var rhs = self.pop();
        var lhs = self.pop();
        self.push(lhs - rhs);
    }
    self.sub = sub;
    
    var jlq = function()
    {
        var rhs = self.pop();
        var addr = self.pop();
        var lhs = self.pop();
        if (lhs <= rhs)
        {
            self.programCounter = addr;
        }
    }
    self.jlq = jlq;
    
    var call = function()
    {
        var addr = self.pop();
        var backupState = {
        programCounter: self.programCounter + 1, // Auto increment so we don't loop forever
        dataRegister: self.dataRegister,
        backupRegister: self.backupRegister
        };
        
        self.callstack.push(backupState);
        self.dataRegister = 0x0;
        self.backupRegister = 0x0;
        self.programCounter = addr;
    }
    self.call = call;
    
    var ret = function()
    {
        var backupState = self.callstack.pop();
        self.dataRegister = backupState.dataRegister;
        self.backupRegister = backupState.backupRegister;
        self.programCounter = backupState.programCounter;
        
    }
    self.ret = ret;
    
    var interrupt = function()
    {
        var intCode = self.pop();
        var theInterrupt = self.interruptTable[intCode];
        theInterrupt.callback(self);
    }
    self.interrupt = interrupt;
    
    var addInterrupt = function(code, callback)
    {
        self.interruptTable[code] = {
        code: code,
        callback: callback
        };
        
    }
    self.addInterrupt = addInterrupt;
    
    var replaceInterrupt = function(code, callback)
    {
        self.interruptTable[code] = {
        code: code,
        callback: callback
        };
    }
    self.replaceInterrupt = replaceInterrupt;
    
    var loadBinary = function(binary, baseAddress)
    {
        for (var i = 0; i < binary.length; i += 1)
        {
            self.ram.setByte(binary[i], i + baseAddress);
        }
    }
    self.loadBinary = loadBinary;
    
    var executeNextInstruction = function()
    {
        var pcBackup = self.programCounter;
        var nextInstr = self.ram.getByte(self.programCounter);
        var instrSize = 0x1;
        if (nextInstr === 0x1)
        {
            // sub
            self.sub();
        }
        else if (nextInstr === 0x2)
        {
            // jlq
            self.jlq();
        }
        else if (nextInstr === 0x3)
        {
            // push
            instrSize = 0x2;
            var theArgument = self.ram.getByte(self.programCounter + 1);
            self.push(theArgument);
        }
        else if (nextInstr === 0x4)
        {
            // pop
            self.pop();
        }
        else if (nextInstr === 0x5)
        {
            // int
            self.interrupt();
        }
        else if (nextInstr === 0x6)
        {
            // call
            self.call();
        }
        else if (nextInstr === 0x7)
        {
            // ret
            self.ret();
        }
        else
        {
            // brk
            self.breakFlag = 0x1;
        }
        
        if (self.programCounter === pcBackup)
        {
            // PC was not changed by the instruction, auto increment
            self.programCounter += instrSize;
        }
    }
    self.executeNextInstruction = executeNextInstruction;
    
    var setupBaseInterrupts = function()
    {
        self.addInterrupt(0x0, function(cpu) {
                          cpu.push(cpu.programCounter);
                          });
        
        self.addInterrupt(0x1, function(cpu) {
                          var addr = cpu.pop();
                          var val = cpu.pop();
                          cpu.ram.setByte(val, addr);
                          });
        
        self.addInterrupt(0x2, function(cpu) {
                          var addr = cpu.pop();
                          var val = cpu.ram.getByte(addr);
                          cpu.push(val);
                          });
        
        self.addInterrupt(0x3, function(cpu) {
                          cpu.dataRegister = cpu.pop();
                          });
        
        self.addInterrupt(0x4, function(cpu) {
                          cpu.push(cpu.dataRegister);
                          });
        
        self.addInterrupt(0x5, function(cpu) {
                          cpu.backupRegister = cpu.pop();
                          });
        
        self.addInterrupt(0x6, function(cpu) {
                          cpu.push(cpu.backupRegister);
                          });
        
        self.addInterrupt(0x7, function(cpu) {
                          cpu.printCache += String.fromCharCode(cpu.pop());
                          });
        
        self.addInterrupt(0x8, function(cpu) {
                          cpu.printCache += " ";
                          });
        
        self.addInterrupt(0x9, function(cpu) {
                          console.log(cpu.printCache);
                          cpu.printCache = "";
                          });
        
        self.addInterrupt(0xdeadface, function(cpu) {
                          debugger;
                          });
        
        
    }
    setupBaseInterrupts();
    return self;
}
