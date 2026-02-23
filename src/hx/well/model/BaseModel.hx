package hx.well.model;

import hx.well.database.query.QueryBuilder;
import hx.well.http.Response;
import hx.well.http.JsonResponse;
import hx.well.http.IResponseInstance;
import hx.well.interfaces.ISerializable;

// TODO: Add support for timestamps (created_at, updated_at)
// TODO: Add support for saving (save())
@:autoBuild(hx.well.macro.ModelMacro.build())
class BaseModel<T> implements IResponseInstance implements ISerializable {
	public var __connection:String = "default";
	public var __table:String;
	public var __primary:String;
	private var __visibleFields:Array<String> = [];

	public function new() {}

	public function primaryKeyFactory():Dynamic {
		return null;
	}

	public function delete():Void {
		primaryQuery().delete();
	}

	public function update(data:Map<String, Dynamic>):Void {
		primaryQuery().update(data);
	}

	public inline function getTable():String {
		return __table;
	}

	public function setTable(value:String):Void {
		__table = value;
	}

	public function setConnection(value:String):Void {
		__connection = value;
	}

	public function getPrimary():String {
		return __primary;
	}

	public function setPrimary(value:String):Void {
		__primary = value;
	}

	public function getDatabaseFields():Array<String> {
		return [];
	}

	public function getVisibleDatabaseFields():Array<String> {
		return __visibleFields;
	}

	public overload extern inline function makeVisible(attribute:String):Void {
		makeVisibleInternal(attribute);
	}

	public overload extern inline function makeVisible(attributes:Array<String>):Void {
		for(attribute in attributes)
			makeVisible(attribute);
	}

	public overload extern inline function makeVisible(attributes:...String):Void {
		for(attribute in attributes)
			makeVisible(attribute);
	}

	public overload extern inline function makeHidden(attribute:String):Void {
		makeHiddenInternal(attribute);
	}

	public overload extern inline function makeHidden(attributes:Array<String>):Void {
		for(attribute in attributes)
			makeHidden(attribute);
	}

	public overload extern inline function makeHidden(attributes:...String):Void {
		for(attribute in attributes)
			makeHidden(attribute);
	}

	private function makeVisibleInternal(attribute:String):Void {
		if (!__visibleFields.contains(attribute)) {
			__visibleFields.push(attribute);
		}
	}

	private function makeHiddenInternal(attribute:String):Void {
		__visibleFields.remove(attribute);
	}

	/**
	 * Convert this model to a plain object containing only visible fields.
	 * Useful for serialization, API responses, and data transfer.
	 * @return Dynamic object with visible fields only
	 */
	public function toObject():Dynamic {
		var data:Dynamic = {};

		for (field in getVisibleDatabaseFields()) {
			var fieldValue:Dynamic = Reflect.getProperty(this, field);
			Reflect.setProperty(data, field, fieldValue);
		}

		return data;
	}

	/**
	 * Get a JSON response containing only visible fields.
	 * @return JsonResponse with visible model data
	 */
	public function getResponse():Response {
		return new JsonResponse(toObject());
	}

	// Internal Helpers
	private inline function primaryFieldValue():Dynamic {
		return Reflect.field(this, __primary);
	}

	private function primaryQuery():QueryBuilder<T> {
		return new QueryBuilder(this).where(__primary, primaryFieldValue());
	}
}
