/**
 * Brian Wu
 * Book: Blockchain Quick Start Guide
 */
App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',
  init: async function() {
    return await App.initWeb3();
  },

  initWeb3: async function() {
    // TODO: refactor conditional
    App.web3Provider = new Web3.providers.HttpProvider('http://localhost:8545');
    web3 = new Web3(App.web3Provider);
    // if (typeof web3 !== 'undefined') {
    //   // If a web3 instance is already provided by Meta Mask.
    //   App.web3Provider = web3.currentProvider;
    //   web3 = new Web3(web3.currentProvider);
    // } else {
    //   // Specify default instance if no web3 instance provided
    //   App.web3Provider = new Web3.providers.HttpProvider('http://localhost:8545');
    //   web3 = new Web3(App.web3Provider);
    // }
    return App.initContract();
  },

  initContract: function() {
    App.bindEvents();
    App.loadProject();
  },

  bindEvents: function() {
    $(document).on('click', '#contributionBtn', App.handleContribution);
    $(document).on('click', '#destroy', App.handleDestroy);
    $(document).on('click', '#checkGoal', App.handleCheckGoal);
    $(document).on('click', '#fundBtn', App.handleFund);
  },

  handleCheckGoal: function(event) {
    event.preventDefault();
    $("#displayMsg").html("");
    var selectAcct = $('#accts').find(":selected").val();
    var loader = $("#loader");
    loader.show();
    App.contracts.CrowdFunding.deployed().then(function(instance) {
      return instance.checkGoalReached({ from: selectAcct, gas:3500000});
    }).then(function(result) {
      loader.hide();
      App.loadProject();
    }).catch(function(err) {
      loader.hide();
      console.error(err);
      $("#displayMsg").html(err);
    });
  },

  handleDestroy: function(event) {
    event.preventDefault();
    $("#displayMsg").html("");
    var selectAcct = $('#accts').find(":selected").val();
    var loader = $("#loader");
    loader.show();
    App.contracts.CrowdFunding.deployed().then(function(instance) {
      return instance.destroy({ from: selectAcct, gas:3500000});
    }).then(function(result) {
      loader.hide();
    }).catch(function(err) {
      loader.hide();
      console.error(err);
      $("#displayMsg").html(err);
    });
  },
  handleContribution: function(event) {
    event.preventDefault();
    $("#displayMsg").html("");
    var contributionVal =  $('#contributionInput').val();
    var loader = $("#loader");
    loader.show();
    App.contracts.CrowdFunding.deployed().then(function(instance) {
      return instance.contributions(contributionVal);

    }).then(function(result) {
      console.log(result);
      $("#contr-address").text(result[0].toString());
      $("#contr-amount").text(result[1].toString());
      loader.hide();
    }).catch(function(err) {
      loader.hide();
      $("#contr-address").text("");
      $("#contr-amount").text("");
      console.error(err);
      $("#displayMsg").html(err);
    });
  },
  handleFund: function(event) {
    event.preventDefault();
    var fundVal =  $('#ageOutputId').val();
    var selectAcct = $('#accts').find(":selected").val();
    var loader = $("#loader");
    $("#displayMsg").html("");
    loader.show();
    App.contracts.CrowdFunding.deployed().then(function(instance) {
      return instance.fund({ from: selectAcct, value:web3.toWei(fundVal, "ether"), gas:3500000});

    }).then(function(result) {
      loader.hide();
      App.loadProject();
    }).catch(function(err) {
      loader.hide();
      console.error(err);
      $("#displayMsg").html(err);
    });
  },
  loadProject: function(event) {
    $("#displayMsg").html("");
    $.getJSON("CrowdFunding.json", function(crowdFunding) {
      // Instantiate a new truffle contract from the artifact
      App.contracts.CrowdFunding = TruffleContract(crowdFunding);
      // Connect provider to interact with contract
      App.contracts.CrowdFunding.setProvider(App.web3Provider);
        return App.render();
    });
  },
  render: function() {
    var crowdFundingInstance;
    var loader = $("#loader");
    loader.show();
    // Load account data
    var i =0; 
    $('#accts').empty();
    web3.eth.accounts.forEach( function(e){
        $('#accts').append($('<option>', { 
            value:e,
            text : e + " (" +web3.fromWei(web3.eth.getBalance(e), "ether") + " ether)"
        }));
    })
    // Load contract data
    App.contracts.CrowdFunding.deployed().then(function(instance) {
      crowdFundingInstance = instance;
      return crowdFundingInstance.project();
    }).then(function(projectInfo) {
        $("#address").text(projectInfo[0].toString());
        $("#name").text(projectInfo[1]);
        $("#website").text(projectInfo[2]);
        $("#totalRaised").text(projectInfo[3].toString());
        $("#minimumToRaise").text(projectInfo[4].toString());
        $("#currentBalance").text(projectInfo[5].toString());
        if(projectInfo[6].toString().length>0) {
          var deadline = new Date(Number(projectInfo[6].toString())*1000);
          deadlineDate = moment(deadline).format("YYYY-MM-DD h:mm:ss");
          $("#deadline").text(deadlineDate);
        } 
        if(projectInfo[7].toString().length>0 && projectInfo[7].toString()!='0') {
          console.log(projectInfo[7].toString());
          var completeAt = new Date(Number(projectInfo[7].toString())*1000);
          completeAtDate = moment(completeAt).format("YYYY-MM-DD h:mm:ss");
          $("#completeAt").text(completeAtDate);
        }    
        var status =projectInfo[8].toString();
        var statusTxt = "";
        if(status=='0') {
          statusTxt ="Fundraising";
          $("#status").text(statusTxt).css({"color":"orange"});;
        } else if(status=='1') {
          statusTxt ="Fail";
          $("#status").text(statusTxt).css({"color":"red"});;
        } else if(status=='2') {
          statusTxt ="Successful";
          $("#status").text(statusTxt).css({"color":"green"});;
        }
        
        loader.hide();
    }).catch(function(error) {
      console.warn(error);
      loader.hide();
      $("#displayMsg").html(err);
    });
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
  
});
