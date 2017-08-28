// JS implementation of MinimalRAM
function MinimalRAM() {
    var self = this;
    
    var REGION_SIZE = 2048;
    
    // Memory regions
    self.regions = [];
    
    /// Returns aligned base address for a region that would own this address
    var alignedRegionBase = function(address)
    {
        // Offset from alignment
        var offset = (address % REGION_SIZE);
        // Subtract offset
        return address - offset;
    };
    
    /// Returns the localized address for a region
    var localizedAddress(address)
    {
        // Figure out offset from an aligned base & return it
        return address % REGION_SIZE;
    }
    
    /// Adds a region that will own this address
    var addRegion = function(address)
    {
        // Align address
        var alignedBase = alignedRegionBase(address);
        // create region
        var newRegion = {
            baseAddress = alignedBase,
            data = Array.apply(null, Array(REGION_SIZE)).map(Number.prototype.valueOf, 0)
        };
        // add region
        self.regions.push(newRegion);
    };
    
    /// Get the region that owns the region, or null if it doesn't exist
    var getRegion = function(address)
    {
        // Find region owning address
        for (var i = 0; i < self.regions.length; i += 1)
        {
            var theRegion = self.regions[i];
            if (theRegion.baseAddress <= address && theRegion.baseAddress + REGION_SIZE > address)
            {
                // Matched; Return owning region
                return theRegion;
            }
        }
        // Return null if region was not found
        return null;
    };
    
    
    /// Returns true if the region exists, false otherwise
    var hasRegion = function(address)
    {
        // Check if getRegion returns null
        var theRegion = getRegion(address);
        // Return false if null is returned
        return theRegion === null;
    };
    
    /// Sets byte at address
    var setByte = function(val, address)
    {
        // Check if region exists
        if (!hasRegion(address))
        {
            // Add region if it doesn't exist
            addRegion(address);
        }
        
        // Get owning region
        var theRegion = getRegion(address);
        // get localized address
        var laddr = localizedAddress(address);
        
        theRegion.data[laddr] = val;
    };
    self.setByte = setByte;
    
    /// Returns byte at address
    var getByte = function(address)
    {
        if (hasRegion(address))
        {
            var theRegion = getRegion(address);
            var laddr = localizedAddress(address);
            return theRegion.data[laddr];
        }
        else {
            // Return zero if they request a byte that doesn't exist
            return 0;
        }
    };
    self.getByte = getByte;
    
    // Return self
    return self;
}
