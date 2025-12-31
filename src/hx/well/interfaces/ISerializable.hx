package hx.well.interfaces;

/**
 * Interface for objects that can be serialized to a plain object.
 * Useful for API responses, and data transfer.
 * 
 * Any class implementing this interface will be automatically converted
 * to a plain object when passed through serialization systems.
 */
interface ISerializable {
	/**
	 * Convert this instance to a plain object suitable for serialization.
	 * The returned object should only contain data that can be safely
	 * serialized to JSON (no functions, circular references, etc.).
	 * 
	 * @return Dynamic object representation of this instance
	 */
	public function toObject():Dynamic;
}
