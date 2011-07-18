Ext.define("Compass.ErpApp.Desktop.Applications.Knitkit.CommentsGridPanel",{
    extend:"Ext.grid.Panel",
    alias:'knitkit_commentsgridpanel',
    approve : function(rec){
        var self = this;
        self.initialConfig['centerRegion'].setWindowStatus('Approving Comment...');
        var conn = new Ext.data.Connection();
        conn.request({
            url: './knitkit/comments/approve',
            method: 'POST',
            params:{
                id:rec.get("id")
            },
            success: function(response) {
                var obj =  Ext.util.JSON.decode(response.responseText);
                if(obj.success){
                    self.initialConfig['centerRegion'].clearWindowStatus();
                    self.getStore().reload();
                }
                else{
                    Ext.Msg.alert('Error', 'Error approving comemnt');
                    self.initialConfig['centerRegion'].clearWindowStatus();
                }
            },
            failure: function(response) {
                self.initialConfig['centerRegion'].clearWindowStatus();
                Ext.Msg.alert('Error', 'Error approving comemnt');
            }
        });

        
    },

    deleteComment : function(rec){
        var self = this;
        self.initialConfig['centerRegion'].setWindowStatus('Deleting Comment...');
        var conn = new Ext.data.Connection();
        conn.request({
            url: './knitkit/comments/delete',
            method: 'POST',
            params:{
                id:rec.get("id")
            },
            success: function(response) {
                var obj =  Ext.util.JSON.decode(response.responseText);
                if(obj.success){
                    self.initialConfig['centerRegion'].clearWindowStatus();
                    self.getStore().reload();
                }
                else{
                    Ext.Msg.alert('Error', 'Error deleting comemnt');
                    self.initialConfig['centerRegion'].clearWindowStatus();
                }
            },
            failure: function(response) {
                self.initialConfig['centerRegion'].clearWindowStatus();
                Ext.Msg.alert('Error', 'Error deleting comemnt');
            }
        });


    },

    initComponent: function() {
        Compass.ErpApp.Desktop.Applications.Knitkit.CommentsGridPanel.superclass.initComponent.call(this, arguments);
        this.getStore().load();
    },

    constructor : function(config) {
        var self = this;
        var store = new Ext.data.JsonStore({
            root: 'comments',
            totalProperty: 'totalCount',
            idProperty: 'id',
            remoteSort: true,
            fields: [
            {
                name:'id'
            },
            {
                name:'commentor_name'
            },
            {
                name:'email'
            },
            {
                name:'created_at'
            },
            {
                name:'approved?'
            },
            {
                name:'comment'
            },
            {
                name:'approved_by_username'
            },
            {
                name:'approved_at'
            }
            ],
            url:'./knitkit/comments/get/' + config['contentId']
        });

        config = Ext.apply({
            store:store,
            columns:[
            {
                header:'Commentor',
                sortable:true,
                width:150,
                dataIndex:'commentor_name'
            },
            {
                header:'Email',
                sortable:true,
                width:150,
                dataIndex:'email'
            },
            {
                header:'Commented On',
                dataIndex:'created_at',
                width:120,
                sortable:true,
                renderer: Ext.util.Format.dateRenderer('m/d/Y H:i:s')
            },
            {
                menuDisabled:true,
                resizable:false,
                xtype:'actioncolumn',
                header:'View',
                align:'center',
                width:50,
                items:[{
                    icon:'/images/icons/document_view/document_view_16x16.png',
                    tooltip:'View',
                    handler :function(grid, rowIndex, colIndex){
                        var rec = grid.getStore().getAt(rowIndex);
                        self.initialConfig['centerRegion'].showComment(rec.get('comment'));
                    }
                }]
            },
            {
                menuDisabled:true,
                resizable:false,
                xtype:'actioncolumn',
                header:'Approval',
                align:'center',
                width:60,
                items:[{
                    getClass: function(v, meta, rec) {  // Or return a class from a function
                        if (rec.get('approved?')) {
                            this.items[0].tooltip = 'Approved';
                            return 'approved-col';
                        } else {
                            this.items[0].tooltip = 'Approve';
                            return 'approve-col';
                        }
                    },
                    handler: function(grid, rowIndex, colIndex) {
                        var rec = grid.getStore().getAt(rowIndex);
                        if(rec.get('approved?')){
                            return false;
                        }
                        else{
                            grid.approve(rec)
                        }
                    }
                }]
            },
            {
                header:'Approved By',
                sortable:true,
                width:140,
                dataIndex:'approved_by_username'
            },
            {
                header:'Approved At',
                sortable:true,
                width:140,
                dataIndex:'approved_at'
            },
            {
                menuDisabled:true,
                resizable:false,
                xtype:'actioncolumn',
                header:'Delete',
                align:'center',
                width:50,
                items:[{
                    icon:'/images/icons/delete/delete_16x16.png',
                    tooltip:'Delete',
                    handler :function(grid, rowIndex, colIndex){
                        var rec = grid.getStore().getAt(rowIndex);
                        self.deleteComment(rec);
                    }
                }]
            }
            ],
            bbar: new Ext.PagingToolbar({
                pageSize: 10,
                store: store,
                displayInfo: true,
                displayMsg: '{0} - {1} of {2}',
                emptyMsg: "Empty"
            })
        }, config);

        Compass.ErpApp.Desktop.Applications.Knitkit.CommentsGridPanel.superclass.constructor.call(this, config);
    }
});