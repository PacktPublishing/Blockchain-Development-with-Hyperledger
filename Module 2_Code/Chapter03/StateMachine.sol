pragma solidity ^0.4.24;

contract StateMachine {
    
    enum Stages {
        INIT,
        SCRUB,
        RINSE,
        DRY,
        CLEANUP
    }

    Stages public stage = Stages.INIT;
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }
    function nextStage() internal {
        stage = Stages(uint(stage) + 1);
    }   
    modifier transitionNext() {
        _;
        nextStage();
    }
    
    function scrube() public atStage(Stages.INIT)  transitionNext  {
       // Implement scrube logic here
    }

    function rinse() public  atStage(Stages.SCRUB)  transitionNext  {
        // Implement rinse logic here
    }

    function dry() public  atStage(Stages.SCRUB)  transitionNext  {
        // Implement dry logic here
    }

    function cleanup() public view atStage(Stages.CLEANUP) {
        // Implement dishes cleanup 
    }
}