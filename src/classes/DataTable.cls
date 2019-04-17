/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce.com
Description:	Generic container for ojbect records displayed in a table
Test Class:		DataTable_Test

History:
<Date>			<Authors Name>		<Brief Description of Change>
04/01/2016		Denise Bacher		Initial Creation
------------------------------------------------------------*/
public with sharing class DataTable{
	private final static Integer ROWS_TO_DISPLAY = 5; // this value will be used as the table's default page size
	public final static String SORT_UP = 'sort_up';
	public final static String SORT_DOWN = 'sort_down';
	
	public Integer rowsPerPage{ get; set; } // the number of rows that will be displayed on each page of the table
	
	// the table recognizes one 'id' field. This little hack allows a second and third id field
	public String id2Name{ get; set; }
	public String id3Name{ get; set; }
	
	public String extraSort{ get; set; } // this will be appended to the query sort criteria (i.e. '<field1>, <field2> desc')

	public List<SObject> objects{ get; private set; } // objects from the standard set controller
	public final String objectName{ get; private set; } // name of the object in the table
	public final String title{ get; private set; } // title of the table, can be displayed on a VF page
	public List<Column> columns{ get; private set; } 
	public List<Row> rows{ 
	  get{
		  if(rows == null){
		 	rows = new List<Row>();
		  	for (SObject o : objects){
			  	rows.add(new Row(o, columns, id2Name, id3Name));
		  	}
		  }
		  return rows;
	  }
	  private set;
	}
	
	private ApexPages.StandardSetController controller {get; set;} // set controller	

	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Create the table.
	Inputs:			objectName - API name of the object
					title - title of the table
					rowsPerPage - rows per page to display
					sortField - initial field to sort by
					sortDirection - initial direction to sort by
					columns - list of columns in the table
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public DataTable(String objectName, String title, Integer rowsPerPage, String sortField, String sortDirection, List<Column> columns){
		System.assert(String.isNotBlank(objectName), 'objectName param cannot be null');
		System.assert((columns != null) && !columns.isEmpty(), 'columns pram must be provided');
		
		this.objectName = objectName;
		this.title = title;
		this.columns = columns;
		
		this.sortField = String.isBlank(sortField) ? columns[0].field : sortField;
		this.previousSortField = sortField;
		this.sortDirection = sortDirection;
		
		this.objects = new List<SObject>();
		this.rowsPerPage = rowsPerPage == null || rowsPerPage <= 0 ? ROWS_TO_DISPLAY : rowsPerPage;
	}

	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Create the table. By default, sorting will be ASC by the first column, rows will be ROWS_TO_DISPLAY.
	Inputs:			objectName - API name of the object
					title - title of the table
					columns - list of columns in the table
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public DataTable(String objectName, String title, List<Column> columns){
		this(objectName, title, ROWS_TO_DISPLAY, null, null, columns);
	}

	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	populate the table with data
	Inputs:			whereClause - additional 'where' clause to be used in the query. Do not include the word 'WHERE'.
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public void populate(String whereClause){
		String fieldNames = String.isBlank(id2Name) ? '' : id2Name;
		fieldNames += String.isBlank(id3Name) ? '' : (String.isBlank(fieldNames) ? id3Name : ',' + id3Name);
		for (Column c : columns){
			fieldNames += (String.isBlank(fieldNames) ? '' : ', ') + c.field;
		}

		String query = String.format('SELECT {0} FROM {1} {2} ORDER BY {3} {4}', 
			new List<String>{ fieldNames, 
								objectName, 
								String.isBlank(whereClause) ? '' : 'WHERE ' + whereClause,
								sortField + ' ' + sortDirection + ((sortDirection == 'ASC') ? ' NULLS FIRST ' : ' NULLS LAST '),
								String.isBlank(extraSort) ? '' : (',' + extraSort)
							});
		
		System.debug('DataTable query: ' + query);
		try{
			controller = new ApexPages.StandardSetController(Database.getQueryLocator(query));
			controller.setPageSize(rowsPerPage);
			objects = controller.getRecords();
		} 
		catch (Exception e){
			throw new GlobalUtility.GenericException('DataTable.populate: ' + e.getMessage() + ': ' + query);
		}
		
		rows = null;
	}

	//--------------------------------------------------------------------------
	// Sorting
	private String previousSortField{ get; set; } // value of the field previously sorted by

	// if this is set twice to the same value, the sort order is reversed
	public String sortField{ get;
		set{
			Boolean found = false;
			for (Column c : columns){
				if (found = (value == c.field)){
					break;
				}
			}
			
			if (!found){
				value = columns[0].field;
			}

			if (sortField != value){
				sortField = value;
				for (Column c : columns){
					c.order = (value == c.field) ? ((sortDirection == 'ASC') ? SORT_UP : SORT_DOWN) : '';
				}
			}
		}
	}

	// direction of the sort
	public String sortDirection{ get; 
		set{
	  		if (!(new Set<String>{'ASC','DESC'}).contains(value)){
	  			value = 'ASC';
	  		}

			if (sortDirection != value){
				sortDirection = value;
				for (Column c : columns){
					c.order = (sortField == c.field) ? ((value == 'ASC') ? SORT_UP : SORT_DOWN) : '';
				}
			}
		}
	}

	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Set the sortDirection and previousSortField based on the current value of sortField
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public void sort(){
		sortDirection = (previousSortField == sortField) ? (sortDirection == 'ASC' ? 'DESC' : 'ASC') : sortDirection;
		previousSortField = sortField;
	}

	//--------------------------------------------------------------------------
	// Pagination
	public Integer page{ get{ return controller.getPageNumber(); }} // current page
	public Integer pageCount{ get{ return objects.size(); }} // number of records on the current page
	public Integer totalCount{ get{ return controller.getResultSize(); }} // total number of records available
	public Boolean hasNext{ get{ return controller.getHasNext(); }} // has next page
	public Boolean hasPrevious{ get{ return controller.getHasPrevious(); }} // has previous page
	
	// text that reads 'Records I to J of N', to be used on a VF page
	public String recordsItoJofN{
		get{
			final Integer n = (page - 1) * rowsPerPage;
			return String.format(System.Label.lbl_RecordsRangeOfN, new String[]{
				String.valueOf((totalCount > 0) ? n+1 : n),
				String.valueOf(n + pageCount),
				String.valueOf(totalCount)
			});
		}
	}
	
	// text that reads 'Page X of N', to be used on a VF page
	public String pageXofN{
		get{
			final Decimal n = totalCount != 0 ? ((Decimal)totalCount/(Decimal)rowsPerPage).round(System.RoundingMode.UP) : 0;
			return String.format(System.Label.lbl_PageXofN, new String[]{
				String.valueOf(page),
				String.valueOf(n)
			});
		}
	}

	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Navigate to the first page in the set controller
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public void firstPage(){
		controller.first();
		rows = null;
		objects = controller.getRecords(); 
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Navigate to the last page in the set controller
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public void lastPage(){ 
		controller.last(); 
		rows = null;
		objects = controller.getRecords(); 
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Navigate to the previous page in the set controller
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public void previousPage(){ 
		controller.previous(); 
		rows = null;
		objects = controller.getRecords(); 
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Navigate to the next page in the set controller
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public void nextPage(){ 
		controller.next(); 
		rows = null;
		objects = controller.getRecords(); 
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	a Column in the table; provides a field specification, label, sorting, and style.
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public class Column{
		public final String label{ get; private set; } // column label
		public final String field{ get; private set; } // api field name, may not be null or blank
		public final String styleClass{ get; private set; } // style class to associate with the column
		public final Boolean allowSort{ get; private set; } // should this column allow sorting?
		public String order{ get; set; }

		/*------------------------------------------------------------
		Author:			Denise Bacher
		Company:		Salesforce.com
		Description:	constructor
		Inputs:			label - label of the column
						field - api field name to be queried, may not be null or blank
						styleClass - optional style class to apply to the columnn (on VF page)
						allowSort - define if this column can be sorted by
		
		History:
		<Date>			<Authors Name>		<Brief Description of Change>
		04/01/2016		Denise Bacher		Initial Creation
		------------------------------------------------------------*/
		public Column(String label, String field, String styleClass, Boolean allowSort){
			System.assert(String.isNotBlank(field));

			this.label = label;
			this.field = field;
			this.styleClass = styleClass;
			this.allowSort = allowSort;
		}

		public Column(String label, String field){
			this(label, field, '', true);
		}
	}

	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	a Row in the table; provides a field list specification, Id, secondary Id, tertiary Id field.
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public class Row{
		public final List<Field> fields{ get; private set; } // list of fields for this row
		public final Id id{ get; private set; } // id of the SObject 
		public final Id id2{ get; private set; } // secondary id to be used, ie: id to a related record
		public final Id id3{ get; private set; } // tertiary id to be used, ie: id to a related record
		public Boolean isSelected{ get; set; } // allows the row to be selected for additional opperations
		private List<Column> columns; // list of columns that make up the fields in this row

		/*------------------------------------------------------------
		Author:			Denise Bacher
		Company:		Salesforce.com
		Description:	constructor
		Inputs:			obj - the SObject representing one row of the table; must not be null
						columns - the fields making up the row; must not be null
						id2Name - an optional second Id
						id3Name - an optional third Id
		
		History:
		<Date>			<Authors Name>		<Brief Description of Change>
		04/01/2016		Denise Bacher		Initial Creation
		------------------------------------------------------------*/
		public Row(SObject obj, List<Column> columns, String id2Name, String id3Name){
			System.assert(null != obj, 'obj param cannot be null');
			System.assert(null != columns, 'columns param cannot be null');
			
			this.columns = columns;
			fields = new List<Field>();
			id = String.valueOf(obj.get('Id'));
			id2 = String.isBlank(id2Name) ? null : String.valueOf(obj.get(id2Name));
			id3 = String.isBlank(id3Name) ? null : String.valueOf(obj.get(id3Name));
			isSelected = false;
			
			for (Column c : columns){
				String text;
				Object field = this.getValue(obj, c.field);
				if (field == null){
					text = '';
				} 
				else if (field instanceOf Date){
					Date d = (Date)field; 
					text = d.format();
				} 
				else if (field instanceOf DateTime){
					DateTime dt = (DateTime)field; 
					text = dt.format();
				} 
				else{
					text = String.valueOf(field);
				}

				fields.add(new Field(c.label, c.field, text.trim(), c.styleClass));
			}
		}

		/*------------------------------------------------------------
		Author:			Denise Bacher
		Company:		Salesforce.com
		Description:	get the value for the specified SObject and field.
		Inputs:			obj - the SObject representing one row of the table; must not be null
						field - name of the field
		
		History:
		<Date>			<Authors Name>		<Brief Description of Change>
		04/01/2016		Denise Bacher		Initial Creation
		------------------------------------------------------------*/
		private Object getValue(SObject obj, String field){
			Integer sep;
			while (obj != null && (sep = field.indexOf('.')) > 0){ 
				obj = obj.getSObject(field.substring(0, sep));
				field = field.subString(sep + 1);
			}
			
			return (obj == null) ? null : obj.get(field);
		}
	}

	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	a Field in the table; provides a name, value, and style
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/01/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	public class Field{
		public final String label{ get; private set; } // object field label name
		public final String name{ get; private set; } // object field api name
		public final String value{ get; private set; } // field value
		public final String styleClass{ get; private set; } // style class to associate with the field 
		
		/*------------------------------------------------------------
		Author:			Denise Bacher
		Company:		Salesforce.com
		Description:	constructor
		Inputs:			label - label of the field
						name - api field name
						value - value of the field
						styleClass - optional style class to apply to the field (on VF page)
		
		History:
		<Date>			<Authors Name>		<Brief Description of Change>
		04/01/2016		Denise Bacher		Initial Creation
		------------------------------------------------------------*/
		public Field(String label, String name, String value, String styleClass){
			this.label = label;
			this.name = name;
			this.value = value;
			this.styleClass = styleClass;
		}
	}
}