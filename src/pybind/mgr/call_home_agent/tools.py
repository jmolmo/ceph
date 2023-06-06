from typing import Any
from functools import wraps


def lock_attributes(cls: Any) -> Any:
    cls.__locked = False
    accepted_types = (str, int, list, tuple, range, set, dict)

    def lock_attr(self: Any, key: str, value: Any) -> None:
        if self.__locked and not hasattr(self, key):
            raise Exception("Class {} has attributes locked. Cannot set {} = {}"
                            .format(cls.__name__, key, value))
        elif not key.startswith('_') and not isinstance(value, accepted_types) and value is not None:
            raise Exception("{} = {}({}). Wrong attribute type, it must be {}"
                            .format(key, value, type(value), accepted_types))
        else:
            object.__setattr__(self, key, value)

    def init_decorator(func: Any) -> Any:
        @wraps(func)
        def wrapper(self, *args, **kwargs):  # type: ignore
            func(self, *args, **kwargs)
            self.__locked = True
        return wrapper

    cls.__setattr__ = lock_attr
    cls.__init__ = init_decorator(cls.__init__)

    return cls
