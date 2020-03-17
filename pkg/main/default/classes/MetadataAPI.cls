/**
* Copyright (c) 2012, FinancialForce.com, inc
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
*   are permitted provided that the following conditions are met:
*
* - Redistributions of source code must retain the above copyright notice,
*      this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright notice,
*      this list of conditions and the following disclaimer in the documentation
*      and/or other materials provided with the distribution.
* - Neither the name of the FinancialForce.com, inc nor the names of its contributors
*      may be used to endorse or promote products derived from this software without
*      specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
*  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
*  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
*  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
*  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
*  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
*  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/
public class MetadataAPI {
	public static final String NAMESPACE_PREFIX =
		String.isBlank(Salesforce.namespace) ? '' : Salesforce.namespace + '__';
	private static final String SOAP_M_URI = 'http://soap.sforce.com/2006/04/metadata';
	public virtual class Metadata {
		public String fullName;
	}
	public class RemoteSiteSetting extends Metadata {
		public String type = 'RemoteSiteSetting';
		public String fullName;
		private String[] fullName_type_info = new String[] { 'fullName', SOAP_M_URI, null, '0', '1', 'false' };
		public String description;
		public Boolean disableProtocolSecurity;
		public Boolean isActive;
		public String url;
		private String[] description_type_info = new String[] { 'description', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] disableProtocolSecurity_type_info = new String[] { 'disableProtocolSecurity', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] isActive_type_info = new String[] { 'isActive', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] url_type_info = new String[] { 'url', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] type_att_info = new String[] { 'xsi:type' };
		private String[] field_order_type_info = new String[] { 'fullName', 'description', 'disableProtocolSecurity', 'isActive', 'url' };
	}
	public class listMetadataResponse_element {
		public MetadataAPI.FileProperties[] result;
		private String[] result_type_info = new String[] { 'result', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'result' };
	}
	public class createMetadata_element {
		public MetadataAPI.Metadata[] metadata;
		private String[] metadata_type_info = new String[] { 'metadata', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'metadata' };
	}
	public class createMetadataResponse_element {
		public MetadataAPI.SaveResult[] result;
		private String[] result_type_info = new String[] { 'result', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'result' };
	}
	public class deleteMetadataResponse_element {
		public MetadataAPI.DeleteResult[] result;
		private String[] result_type_info = new String[] { 'result', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'result' };
	}
	public class LogInfo {
		public String category;
		public String level;
		private String[] category_type_info = new String[] { 'category', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] level_type_info = new String[] { 'level', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'category', 'level' };
	}
	public class QuickActionList {
		public MetadataAPI.QuickActionListItem[] quickActionListItems;
		private String[] quickActionListItems_type_info = new String[] { 'quickActionListItems', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'quickActionListItems' };
	}
	public class RelatedList {
		public Boolean hideOnDetail;
		public String name;
		private String[] hideOnDetail_type_info = new String[] { 'hideOnDetail', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] name_type_info = new String[] { 'name', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'hideOnDetail', 'name' };
	}
	public class FeedLayout {
		public Boolean autocollapsePublisher;
		public Boolean compactFeed;
		public String feedFilterPosition;
		public MetadataAPI.FeedLayoutFilter[] feedFilters;
		public Boolean fullWidthFeed;
		public Boolean hideSidebar;
		public Boolean highlightExternalFeedItems;
		public MetadataAPI.FeedLayoutComponent[] leftComponents;
		public MetadataAPI.FeedLayoutComponent[] rightComponents;
		public Boolean useInlineFiltersInConsole;
		private String[] autocollapsePublisher_type_info = new String[] { 'autocollapsePublisher', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] compactFeed_type_info = new String[] { 'compactFeed', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] feedFilterPosition_type_info = new String[] { 'feedFilterPosition', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] feedFilters_type_info = new String[] { 'feedFilters', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] fullWidthFeed_type_info = new String[] { 'fullWidthFeed', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] hideSidebar_type_info = new String[] { 'hideSidebar', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] highlightExternalFeedItems_type_info = new String[] { 'highlightExternalFeedItems', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] leftComponents_type_info = new String[] { 'leftComponents', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] rightComponents_type_info = new String[] { 'rightComponents', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] useInlineFiltersInConsole_type_info = new String[] { 'useInlineFiltersInConsole', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'autocollapsePublisher', 'compactFeed', 'feedFilterPosition', 'feedFilters', 'fullWidthFeed', 'hideSidebar', 'highlightExternalFeedItems', 'leftComponents', 'rightComponents', 'useInlineFiltersInConsole' };
	}
	public class ReportChartComponentLayoutItem {
		public Boolean cacheData;
		public String contextFilterableField;
		public String error;
		public Boolean hideOnError;
		public Boolean includeContext;
		public String reportName;
		public Boolean showTitle;
		public String size;
		private String[] cacheData_type_info = new String[] { 'cacheData', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] contextFilterableField_type_info = new String[] { 'contextFilterableField', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] error_type_info = new String[] { 'error', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] hideOnError_type_info = new String[] { 'hideOnError', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] includeContext_type_info = new String[] { 'includeContext', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] reportName_type_info = new String[] { 'reportName', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] showTitle_type_info = new String[] { 'showTitle', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] size_type_info = new String[] { 'size', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'cacheData', 'contextFilterableField', 'error', 'hideOnError', 'includeContext', 'reportName', 'showTitle', 'size' };
	}
	public class ListMetadataQuery {
		public String folder;
		public String type_x;
		private String[] folder_type_info = new String[] { 'folder', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] type_x_type_info = new String[] { 'type', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'folder', 'type_x' };
	}
	public class Error {
		public String[] fields;
		public String message;
		public String statusCode;
		private String[] fields_type_info = new String[] { 'fields', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] message_type_info = new String[] { 'message', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] statusCode_type_info = new String[] { 'statusCode', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'fields', 'message', 'statusCode' };
	}
	public class DebuggingHeader_element {
		public MetadataAPI.LogInfo[] categories;
		public String debugLevel;
		private String[] categories_type_info = new String[] { 'categories', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] debugLevel_type_info = new String[] { 'debugLevel', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'categories', 'debugLevel' };
	}
	public class QuickActionListItem {
		public String quickActionName;
		private String[] quickActionName_type_info = new String[] { 'quickActionName', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'quickActionName' };
	}
	public class CustomConsoleComponents {
		public MetadataAPI.PrimaryTabComponents primaryTabComponents;
		public MetadataAPI.SubtabComponents subtabComponents;
		private String[] primaryTabComponents_type_info = new String[] { 'primaryTabComponents', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] subtabComponents_type_info = new String[] { 'subtabComponents', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'primaryTabComponents', 'subtabComponents' };
	}
	public class SummaryLayoutItem {
		public String customLink;
		public String field;
		public Integer posX;
		public Integer posY;
		public Integer posZ;
		private String[] customLink_type_info = new String[] { 'customLink', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] field_type_info = new String[] { 'field', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] posX_type_info = new String[] { 'posX', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] posY_type_info = new String[] { 'posY', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] posZ_type_info = new String[] { 'posZ', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'customLink', 'field', 'posX', 'posY', 'posZ' };
	}
	public class LayoutSection {
		public Boolean customLabel;
		public Boolean detailHeading;
		public Boolean editHeading;
		public String label;
		public MetadataAPI.LayoutColumn[] layoutColumns;
		public String style;
		private String[] customLabel_type_info = new String[] { 'customLabel', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] detailHeading_type_info = new String[] { 'detailHeading', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] editHeading_type_info = new String[] { 'editHeading', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] label_type_info = new String[] { 'label', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] layoutColumns_type_info = new String[] { 'layoutColumns', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] style_type_info = new String[] { 'style', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'customLabel', 'detailHeading', 'editHeading', 'label', 'layoutColumns', 'style' };
	}
	public class RelatedContent {
		public MetadataAPI.RelatedContentItem[] relatedContentItems;
		private String[] relatedContentItems_type_info = new String[] { 'relatedContentItems', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'relatedContentItems' };
	}
	public class SessionHeader_element {
		public String sessionId;
		private String[] sessionId_type_info = new String[] { 'sessionId', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'sessionId' };
	}
	public class SidebarComponent {
		public String componentType;
		public Integer height;
		public String label;
		public String lookup;
		public String page_x;
		public MetadataAPI.RelatedList[] relatedLists;
		public String unit;
		public Integer width;
		private String[] componentType_type_info = new String[] { 'componentType', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] height_type_info = new String[] { 'height', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] label_type_info = new String[] { 'label', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] lookup_type_info = new String[] { 'lookup', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] page_x_type_info = new String[] { 'page', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] relatedLists_type_info = new String[] { 'relatedLists', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] unit_type_info = new String[] { 'unit', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] width_type_info = new String[] { 'width', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'componentType', 'height', 'label', 'lookup', 'page_x', 'relatedLists', 'unit', 'width' };
	}
	public class SummaryLayout {
		public String masterLabel;
		public Integer sizeX;
		public Integer sizeY;
		public Integer sizeZ;
		public MetadataAPI.SummaryLayoutItem[] summaryLayoutItems;
		public String summaryLayoutStyle;
		private String[] masterLabel_type_info = new String[] { 'masterLabel', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] sizeX_type_info = new String[] { 'sizeX', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] sizeY_type_info = new String[] { 'sizeY', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] sizeZ_type_info = new String[] { 'sizeZ', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] summaryLayoutItems_type_info = new String[] { 'summaryLayoutItems', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] summaryLayoutStyle_type_info = new String[] { 'summaryLayoutStyle', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'masterLabel', 'sizeX', 'sizeY', 'sizeZ', 'summaryLayoutItems', 'summaryLayoutStyle' };
	}
	public class SaveResult {
		public MetadataAPI.Error[] errors;
		public String fullName;
		public Boolean success;
		private String[] errors_type_info = new String[] { 'errors', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] fullName_type_info = new String[] { 'fullName', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] success_type_info = new String[] { 'success', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'errors', 'fullName', 'success' };
	}
	public class DeleteResult {
		public MetadataAPI.Error[] errors;
		public String fullName;
		public Boolean success;
		private String[] errors_type_info = new String[] { 'errors', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] fullName_type_info = new String[] { 'fullName', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] success_type_info = new String[] { 'success', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'errors', 'fullName', 'success' };
	}
	public class PrimaryTabComponents {
		public MetadataAPI.Container[] containers;
		private String[] containers_type_info = new String[] { 'containers', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'containers' };
	}
	public class Layout extends Metadata {
		public String type = 'Layout';
		public String fullName;
		private String[] fullName_type_info = new String[] { 'fullName', SOAP_M_URI, null, '0', '1', 'false' };
		public String[] customButtons;
		public MetadataAPI.CustomConsoleComponents customConsoleComponents;
		public Boolean emailDefault;
		public String[] excludeButtons;
		public MetadataAPI.FeedLayout feedLayout;
		public String[] headers;
		public MetadataAPI.LayoutSection[] layoutSections;
		public MetadataAPI.MiniLayout miniLayout;
		public String[] multilineLayoutFields;
		public MetadataAPI.PlatformActionList platformActionList;
		public MetadataAPI.QuickActionList quickActionList;
		public MetadataAPI.RelatedContent relatedContent;
		public MetadataAPI.RelatedListItem[] relatedLists;
		public String[] relatedObjects;
		public Boolean runAssignmentRulesDefault;
		public Boolean showEmailCheckbox;
		public Boolean showHighlightsPanel;
		public Boolean showInteractionLogPanel;
		public Boolean showKnowledgeComponent;
		public Boolean showRunAssignmentRulesCheckbox;
		public Boolean showSolutionSection;
		public Boolean showSubmitAndAttachButton;
		public MetadataAPI.SummaryLayout summaryLayout;
		private String[] customButtons_type_info = new String[] { 'customButtons', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] customConsoleComponents_type_info = new String[] { 'customConsoleComponents', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] emailDefault_type_info = new String[] { 'emailDefault', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] excludeButtons_type_info = new String[] { 'excludeButtons', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] feedLayout_type_info = new String[] { 'feedLayout', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] headers_type_info = new String[] { 'headers', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] layoutSections_type_info = new String[] { 'layoutSections', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] miniLayout_type_info = new String[] { 'miniLayout', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] multilineLayoutFields_type_info = new String[] { 'multilineLayoutFields', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] platformActionList_type_info = new String[] { 'platformActionList', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] quickActionList_type_info = new String[] { 'quickActionList', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] relatedContent_type_info = new String[] { 'relatedContent', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] relatedLists_type_info = new String[] { 'relatedLists', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] relatedObjects_type_info = new String[] { 'relatedObjects', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] runAssignmentRulesDefault_type_info = new String[] { 'runAssignmentRulesDefault', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] showEmailCheckbox_type_info = new String[] { 'showEmailCheckbox', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] showHighlightsPanel_type_info = new String[] { 'showHighlightsPanel', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] showInteractionLogPanel_type_info = new String[] { 'showInteractionLogPanel', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] showKnowledgeComponent_type_info = new String[] { 'showKnowledgeComponent', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] showRunAssignmentRulesCheckbox_type_info = new String[] { 'showRunAssignmentRulesCheckbox', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] showSolutionSection_type_info = new String[] { 'showSolutionSection', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] showSubmitAndAttachButton_type_info = new String[] { 'showSubmitAndAttachButton', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] summaryLayout_type_info = new String[] { 'summaryLayout', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] type_att_info = new String[] { 'xsi:type' };
		private String[] field_order_type_info = new String[] { 'fullName', 'customButtons', 'customConsoleComponents', 'emailDefault', 'excludeButtons', 'feedLayout', 'headers', 'layoutSections', 'miniLayout', 'multilineLayoutFields', 'platformActionList', 'quickActionList', 'relatedContent', 'relatedLists', 'relatedObjects', 'runAssignmentRulesDefault', 'showEmailCheckbox', 'showHighlightsPanel', 'showInteractionLogPanel', 'showKnowledgeComponent', 'showRunAssignmentRulesCheckbox', 'showSolutionSection', 'showSubmitAndAttachButton', 'summaryLayout' };
	}
	public class CallOptions_element {
		public String client;
		private String[] client_type_info = new String[] { 'client', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'client' };
	}
	public class updateMetadata_element {
		public MetadataAPI.Metadata[] metadata;
		private String[] metadata_type_info = new String[] { 'metadata', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'metadata' };
	}
	public class deleteMetadata_element {
		public String type_x;
		public String[] fullNames;
		private String[] type_x_type_info = new String[] { 'type', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] fullNames_type_info = new String[] { 'fullNames', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'type_x', 'fullNames' };
	}
	public class updateMetadataResponse_element {
		public MetadataAPI.SaveResult[] result;
		private String[] result_type_info = new String[] { 'result', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'result' };
	}
	public class ReadWebLinkResult implements IReadResult {
		public MetadataAPI.WebLink[] records;
		public MetadataAPI.Metadata[] getRecords() {
			List<MetadataAPI.WebLink> webLinks = new List<MetadataAPI.WebLink>();
			if (Collection.isNotEmpty(records)) {
				for (MetadataAPI.WebLink webLink : records) {
					if (String.isNotBlank(webLink.fullName)) webLinks.add(webLink);
				}
			}
			return webLinks;
		}
		private String[] records_type_info = new String[] { 'records', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'records' };
	}
	public class readWebLinkResponse_element implements IReadResponseElement {
		public MetadataAPI.ReadWebLinkResult result;
		public IReadResult getResult() {
			return result;
		}
		private String[] result_type_info = new String[] { 'result', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'result' };
	}
	public class FeedLayoutComponent {
		public String componentType;
		public Integer height;
		public String page_x;
		private String[] componentType_type_info = new String[] { 'componentType', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] height_type_info = new String[] { 'height', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] page_x_type_info = new String[] { 'page', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'componentType', 'height', 'page_x' };
	}
	public class LayoutColumn {
		public MetadataAPI.LayoutItem[] layoutItems;
		public String reserved;
		private String[] layoutItems_type_info = new String[] { 'layoutItems', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] reserved_type_info = new String[] { 'reserved', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'layoutItems', 'reserved' };
	}
	public class RelatedContentItem {
		public MetadataAPI.LayoutItem layoutItem;
		private String[] layoutItem_type_info = new String[] { 'layoutItem', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'layoutItem' };
	}
	public class readMetadata_element {
		public String type_x;
		public String[] fullNames;
		private String[] type_x_type_info = new String[] { 'type', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] fullNames_type_info = new String[] { 'fullNames', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'type_x', 'fullNames' };
	}
	public interface IReadResult {
		MetadataAPI.Metadata[] getRecords();
	}
	public interface IReadResponseElement {
		IReadResult getResult();
	}
	public class ReadLayoutResult implements IReadResult {
		public MetadataAPI.Layout[] records;
		public MetadataAPI.Metadata[] getRecords() {
			List<MetadataAPI.Layout> layouts = new List<MetadataAPI.Layout>();
			if (Collection.isNotEmpty(records)) {
				for (MetadataAPI.Layout layout : records) {
					if (String.isNotBlank(layout.fullName)) layouts.add(layout);
				}
			}
			return layouts;
		}
		private String[] records_type_info = new String[] { 'records', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'records' };
	}
	public class readLayoutResponse_element implements IReadResponseElement {
		public MetadataAPI.ReadLayoutResult result;
		public IReadResult getResult() {
			return result;
		}
		private String[] result_type_info = new String[] { 'result', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'result' };
	}
	public class ReadRemoteSiteSettingResult implements IReadResult {
		public MetadataAPI.RemoteSiteSetting[] records;
		public MetadataAPI.Metadata[] getRecords() {
			List<MetadataAPI.RemoteSiteSetting> rss = new List<MetadataAPI.RemoteSiteSetting>();
			if (Collection.isNotEmpty(records)) {
				for (MetadataAPI.RemoteSiteSetting rs : records) {
					if (String.isNotBlank(rs.fullName)) rss.add(rs);
				}
			}
			return rss;
		}
		private String[] records_type_info = new String[] { 'records', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'records' };
	}
	public class readRemoteSiteSettingResponse_element implements IReadResponseElement {
		public MetadataAPI.ReadRemoteSiteSettingResult result;
		public IReadResult getResult() {
			return result;
		}
		private String[] result_type_info = new String[] { 'result', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'result' };
	}
	public class FileProperties {
		public String createdById;
		public String createdByName;
		public Datetime createdDate;
		public String fileName;
		public String fullName;
		public String id;
		public String lastModifiedById;
		public String lastModifiedByName;
		public Datetime lastModifiedDate;
		public String manageableState;
		public String namespacePrefix;
		public String type_x;
		private String[] createdById_type_info = new String[] { 'createdById', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] createdByName_type_info = new String[] { 'createdByName', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] createdDate_type_info = new String[] { 'createdDate', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] fileName_type_info = new String[] { 'fileName', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] fullName_type_info = new String[] { 'fullName', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] id_type_info = new String[] { 'id', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] lastModifiedById_type_info = new String[] { 'lastModifiedById', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] lastModifiedByName_type_info = new String[] { 'lastModifiedByName', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] lastModifiedDate_type_info = new String[] { 'lastModifiedDate', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] manageableState_type_info = new String[] { 'manageableState', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] namespacePrefix_type_info = new String[] { 'namespacePrefix', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] type_x_type_info = new String[] { 'type', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'createdById', 'createdByName', 'createdDate', 'fileName', 'fullName', 'id', 'lastModifiedById', 'lastModifiedByName', 'lastModifiedDate', 'manageableState', 'namespacePrefix', 'type_x' };
	}
	public class FeedLayoutFilter {
		public String feedFilterType;
		public String feedItemType;
		private String[] feedFilterType_type_info = new String[] { 'feedFilterType', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] feedItemType_type_info = new String[] { 'feedItemType', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'feedFilterType', 'feedItemType' };
	}
	public class RelatedListItem {
		public String[] customButtons;
		public String[] excludeButtons;
		public String[] fields;
		public String relatedList;
		public String sortField;
		public String sortOrder;
		private String[] customButtons_type_info = new String[] { 'customButtons', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] excludeButtons_type_info = new String[] { 'excludeButtons', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] fields_type_info = new String[] { 'fields', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] relatedList_type_info = new String[] { 'relatedList', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] sortField_type_info = new String[] { 'sortField', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] sortOrder_type_info = new String[] { 'sortOrder', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'customButtons', 'excludeButtons', 'fields', 'relatedList', 'sortField', 'sortOrder' };
	}
	public class SubtabComponents {
		public MetadataAPI.Container[] containers;
		private String[] containers_type_info = new String[] { 'containers', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'containers' };
	}
	public class listMetadata_element {
		public MetadataAPI.ListMetadataQuery[] queries;
		public Double asOfVersion;
		private String[] queries_type_info = new String[] { 'queries', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] asOfVersion_type_info = new String[] { 'asOfVersion', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'queries', 'asOfVersion' };
	}
	public class MiniLayout {
		public String[] fields;
		public MetadataAPI.RelatedListItem[] relatedLists;
		private String[] fields_type_info = new String[] { 'fields', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] relatedLists_type_info = new String[] { 'relatedLists', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'fields', 'relatedLists' };
	}
	public class DebuggingInfo_element {
		public String debugLog;
		private String[] debugLog_type_info = new String[] { 'debugLog', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'debugLog' };
	}
	public class Container {
		public Integer height;
		public String region;
		public MetadataAPI.SidebarComponent[] sidebarComponents;
		public String style;
		public String unit;
		public Integer width;
		private String[] height_type_info = new String[] { 'height', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] region_type_info = new String[] { 'region', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] sidebarComponents_type_info = new String[] { 'sidebarComponents', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] style_type_info = new String[] { 'style', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] unit_type_info = new String[] { 'unit', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] width_type_info = new String[] { 'width', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'height', 'region', 'sidebarComponents', 'style', 'unit', 'width' };
	}
	public class LayoutItem {
		public String behavior;
		public String canvas;
		public String component;
		public String customLink;
		public Boolean emptySpace;
		public String field;
		public Integer height;
		public String page_x;
		public MetadataAPI.ReportChartComponentLayoutItem reportChartComponent;
		public String scontrol;
		public Boolean showLabel;
		public Boolean showScrollbars;
		public String width;
		private String[] behavior_type_info = new String[] { 'behavior', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] canvas_type_info = new String[] { 'canvas', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] component_type_info = new String[] { 'component', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] customLink_type_info = new String[] { 'customLink', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] emptySpace_type_info = new String[] { 'emptySpace', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] field_type_info = new String[] { 'field', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] height_type_info = new String[] { 'height', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] page_x_type_info = new String[] { 'page', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] reportChartComponent_type_info = new String[] { 'reportChartComponent', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] scontrol_type_info = new String[] { 'scontrol', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] showLabel_type_info = new String[] { 'showLabel', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] showScrollbars_type_info = new String[] { 'showScrollbars', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] width_type_info = new String[] { 'width', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'behavior', 'canvas', 'component', 'customLink', 'emptySpace', 'field', 'height', 'page_x', 'reportChartComponent', 'scontrol', 'showLabel', 'showScrollbars', 'width' };
	}
	public class WebLink extends Metadata {
		public String type = 'WebLink';
		public String fullName;
		private String[] fullName_type_info = new String[] { 'fullName', SOAP_M_URI, null, '0', '1', 'false' };
		public String availability;
		public String description;
		public String displayType;
		public String encodingKey;
		public Boolean hasMenubar;
		public Boolean hasScrollbars;
		public Boolean hasToolbar;
		public Integer height;
		public Boolean isResizable;
		public String linkType;
		public String masterLabel;
		public String openType;
		public String page_x;
		public String position;
		public Boolean protected_x;
		public Boolean requireRowSelection;
		public String scontrol;
		public Boolean showsLocation;
		public Boolean showsStatus;
		public String url;
		public Integer width;
		private String[] availability_type_info = new String[] { 'availability', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] description_type_info = new String[] { 'description', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] displayType_type_info = new String[] { 'displayType', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] encodingKey_type_info = new String[] { 'encodingKey', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] hasMenubar_type_info = new String[] { 'hasMenubar', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] hasScrollbars_type_info = new String[] { 'hasScrollbars', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] hasToolbar_type_info = new String[] { 'hasToolbar', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] height_type_info = new String[] { 'height', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] isResizable_type_info = new String[] { 'isResizable', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] linkType_type_info = new String[] { 'linkType', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] masterLabel_type_info = new String[] { 'masterLabel', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] openType_type_info = new String[] { 'openType', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] page_x_type_info = new String[] { 'page', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] position_type_info = new String[] { 'position', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] protected_x_type_info = new String[] { 'protected', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] requireRowSelection_type_info = new String[] { 'requireRowSelection', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] scontrol_type_info = new String[] { 'scontrol', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] showsLocation_type_info = new String[] { 'showsLocation', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] showsStatus_type_info = new String[] { 'showsStatus', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] url_type_info = new String[] { 'url', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] width_type_info = new String[] { 'width', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] type_att_info = new String[] { 'xsi:type' };
		private String[] field_order_type_info = new String[] { 'fullName', 'availability', 'description', 'displayType', 'encodingKey', 'hasMenubar', 'hasScrollbars', 'hasToolbar', 'height', 'isResizable', 'linkType', 'masterLabel', 'openType', 'page_x', 'position', 'protected_x', 'requireRowSelection', 'scontrol', 'showsLocation', 'showsStatus', 'url', 'width' };
	}
	public class PlatformActionList {
		public String actionListContext;
		public MetadataAPI.PlatformActionListItem[] platformActionListItems;
		public String relatedSourceEntity;
		private String[] actionListContext_type_info = new String[] { 'actionListContext', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] platformActionListItems_type_info = new String[] { 'platformActionListItems', SOAP_M_URI, null, '0', '-1', 'false' };
		private String[] relatedSourceEntity_type_info = new String[] { 'relatedSourceEntity', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'actionListContext', 'platformActionListItems', 'relatedSourceEntity' };
	}
	public class PlatformActionListItem {
		public String actionName;
		public String actionType;
		public Integer sortOrder;
		public String subtype;
		private String[] actionName_type_info = new String[] { 'actionName', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] actionType_type_info = new String[] { 'actionType', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] sortOrder_type_info = new String[] { 'sortOrder', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] subtype_type_info = new String[] { 'subtype', SOAP_M_URI, null, '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'actionName', 'actionType', 'sortOrder', 'subtype' };
	}
	public class AllOrNoneHeader_element {
		public Boolean allOrNone;
		private String[] allOrNone_type_info = new String[] { 'allOrNone', SOAP_M_URI, null, '1', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { SOAP_M_URI, 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'allOrNone' };
	}
	public class Client {
		public String endpoint_x = Url.getOrgDomainUrl().toExternalForm() + '/services/Soap/m/' + Salesforce.API_VERSION;
		public Map<String, String> inputHttpHeaders_x;
		public Map<String, String> outputHttpHeaders_x;
		public String clientCertName_x;
		public String clientCert_x;
		public String clientCertPasswd_x;
		public Integer timeout_x;
		public MetadataAPI.SessionHeader_element SessionHeader;
		public MetadataAPI.DebuggingInfo_element DebuggingInfo;
		public MetadataAPI.DebuggingHeader_element DebuggingHeader;
		public MetadataAPI.CallOptions_element CallOptions;
		public MetadataAPI.AllOrNoneHeader_element AllOrNoneHeader;
		private String SessionHeader_hns = 'SessionHeader=http://soap.sforce.com/2006/04/metadata';
		private String DebuggingInfo_hns = 'DebuggingInfo=http://soap.sforce.com/2006/04/metadata';
		private String DebuggingHeader_hns = 'DebuggingHeader=http://soap.sforce.com/2006/04/metadata';
		private String CallOptions_hns = 'CallOptions=http://soap.sforce.com/2006/04/metadata';
		private String AllOrNoneHeader_hns = 'AllOrNoneHeader=http://soap.sforce.com/2006/04/metadata';
		private String[] ns_map_type_info = new String[] { SOAP_M_URI, 'MetadataAPI' };
		public MetadataAPI.DeleteResult[] deleteMetadata(String type_x, String[] fullNames) {
			MetadataAPI.deleteMetadata_element request_x = new MetadataAPI.deleteMetadata_element();
			request_x.type_x = type_x;
			request_x.fullNames = fullNames;
			MetadataAPI.deleteMetadataResponse_element response_x;
			Map<String, MetadataAPI.deleteMetadataResponse_element> response_map_x = new Map<String, MetadataAPI.deleteMetadataResponse_element>();
			response_map_x.put('response_x', response_x);
			WebServiceCallout.invoke(
				this,
				request_x,
				response_map_x,
				new String[] {
					endpoint_x,
					'',
					SOAP_M_URI,
					'deleteMetadata',
					SOAP_M_URI,
					'deleteMetadataResponse',
					'MetadataAPI.deleteMetadataResponse_element'
				}
			);
			response_x = response_map_x.get('response_x');
			return response_x.result;
		}
		public MetadataAPI.SaveResult[] updateMetadata(MetadataAPI.Metadata[] metadata) {
			MetadataAPI.updateMetadata_element request_x = new MetadataAPI.updateMetadata_element();
			request_x.metadata = metadata;
			MetadataAPI.updateMetadataResponse_element response_x;
			Map<String, MetadataAPI.updateMetadataResponse_element> response_map_x = new Map<String, MetadataAPI.updateMetadataResponse_element>();
			response_map_x.put('response_x', response_x);
			WebServiceCallout.invoke(
				this,
				request_x,
				response_map_x,
				new String[] {
					endpoint_x,
					'',
					SOAP_M_URI,
					'updateMetadata',
					SOAP_M_URI,
					'updateMetadataResponse',
					'MetadataAPI.updateMetadataResponse_element'
				}
			);
			response_x = response_map_x.get('response_x');
			return response_x.result;
		}
		public MetadataAPI.FileProperties[] listMetadata(final MetadataAPI.ListMetadataQuery[] queries, final Double asOfVersion) {
			MetadataAPI.listMetadata_element request_x = new MetadataAPI.listMetadata_element();
			request_x.queries = queries;
			request_x.asOfVersion = asOfVersion;
			MetadataAPI.listMetadataResponse_element response_x;
			Map<String, MetadataAPI.listMetadataResponse_element> response_map_x = new Map<String, MetadataAPI.listMetadataResponse_element>();
			response_map_x.put('response_x', response_x);
			WebServiceCallout.invoke(
				this,
				request_x,
				response_map_x,
				new String[] {
					endpoint_x,
					'',
					SOAP_M_URI,
					'listMetadata',
					SOAP_M_URI,
					'listMetadataResponse',
					'MetadataAPI.listMetadataResponse_element'
				}
			);
			response_x = response_map_x.get('response_x');
			return response_x.result;
		}
		public MetadataAPI.Metadata[] readMetadata(final String type_x, final String[] fullNames) {
			MetadataAPI.readMetadata_element request_x = new MetadataAPI.readMetadata_element();
			request_x.type_x = type_x;
			request_x.fullNames = fullNames;
			MetadataAPI.IReadResponseElement response_x;
			Map<String, MetadataAPI.IReadResponseElement> response_map_x = new Map<String, MetadataAPI.IReadResponseElement>();
			response_map_x.put('response_x', response_x);
			WebServiceCallout.invoke(
				this,
				request_x,
				response_map_x,
				new String[] {
					endpoint_x,
					'',
					SOAP_M_URI,
					'readMetadata',
					SOAP_M_URI,
					'readMetadataResponse',
					'MetadataAPI.read' + type_x + 'Response_element'
				}
			);
			response_x = response_map_x.get('response_x');
			return response_x.getResult().getRecords();
		}
		public MetadataAPI.SaveResult[] createMetadata(MetadataAPI.Metadata[] metadata) {
			MetadataAPI.createMetadata_element request_x = new MetadataAPI.createMetadata_element();
			request_x.metadata = metadata;
			MetadataAPI.createMetadataResponse_element response_x;
			Map<String, MetadataAPI.createMetadataResponse_element> response_map_x = new Map<String, MetadataAPI.createMetadataResponse_element>();
			response_map_x.put('response_x', response_x);
			WebServiceCallout.invoke(
				this,
				request_x,
				response_map_x,
				new String[] {
					endpoint_x,
					'',
					SOAP_M_URI,
					'createMetadata',
					SOAP_M_URI,
					'createMetadataResponse',
					'MetadataAPI.createMetadataResponse_element'
				}
			);
			response_x = response_map_x.get('response_x');
			return response_x.result;
		}
	}

	private static MetadataAPI.Client client = null;

	public static MetadataAPI.Client getInstance() {
		if (client == null) {
			client = new MetadataAPI.Client();
			client.SessionHeader = new MetadataAPI.SessionHeader_element();
			client.SessionHeader.sessionId = UserInfo.getSessionId();
			client.timeout_x = Integer.valueOf(AccountSettings__c.getOrgDefaults().CalloutTimeout__c);
			client.AllOrNoneHeader = new MetadataAPI.AllOrNoneHeader_element();
			client.AllOrNoneHeader.allOrNone = true;
			client.CallOptions = new MetadataAPI.CallOptions_element();
			client.CallOptions.client = [
				SELECT SoapClientId__c
				FROM Organization__mdt
				WHERE DeveloperName = 'Current'
				LIMIT 1
			].SoapClientId__c;
		}
		return client;
	}
}
