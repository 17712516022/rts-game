class_name BTNode extends RefCounted

enum Status{
	SUCCESS,FALIURE,RUNNING
}

func tick(_ctx : Dictionary ) -> int:
	return Status.SUCCESS
